function EYE = epoch(EYE, varargin)

%   Inputs
% epochDescriptions--struct array
% baselineDescriptions--struct array
% epochsToCorrect--cell array of epoch names or 'default' for the ones already in previous struct array
% correctionType--char description of correction type or 'none' for no baseline correction
%   Possible correction types:
%       'subtract baseline mean'
%       'percent change from baseline mean'
%       'none'

correctionOptions = {'none'
    'subtract baseline mean'
    'percent change from baseline mean'};

p = inputParser;
addParameter(p, 'epochDescriptions', []);
addParameter(p, 'rejectionThreshold', []);
addParameter(p, 'baselineDescriptions', []);
addParameter(p, 'epochsToCorrect', []);
addParameter(p, 'correctionType', []);
addParameter(p, 'UI', []);
parse(p, varargin{:});

if isempty(p.Results.epochDescriptions)
    q = sprintf('Simple epoching?\n(All epochs of same length and\ndefined using single events)');
    if strcmp(questdlg(q, q, 'Yes', 'No', 'No'), 'Yes')
        eventTypes = unique(mergefields(EYE, 'event', 'type'));
        eventTypes = eventTypes(listdlg('PromptString', 'Epoch which events?',...
            'ListString', eventTypes));
        epochLims = str2double(inputdlg(...
            {'Epochs defined from this many seconds before events:'
            'To this many seconds after:'}));
        baselineLims = str2double(inputdlg(...
            {'Baselines defined from this many seconds before events:'
            'To this many seconds after:'}));
        [epochDescriptions, baselineDescriptions] = deal(struct([]));
        for eventTypeIdx = 1:numel(eventTypes)
            epochDescriptions = cat(2, epochDescriptions,...
                struct('name', eventTypes{eventTypeIdx},...
                    'lims', struct(...
                        'event', eventTypes{eventTypeIdx},...
                        'instance', 0,...
                        'bookend', {-epochLims(1) epochLims(2)})));
            baselineDescriptions = cat(2, baselineDescriptions,...
                struct('name', eventTypes{eventTypeIdx},...
                    'lims', struct(...
                        'event', eventTypes{eventTypeIdx},...
                        'instance', 0,...
                        'bookend', {-baselineLims(1) baselineLims(2)})));
        end
        [baselineDescriptions.epochsToCorrect] = epochDescriptions.name;
    else
        epochDescriptions = UI_getspandescriptions(EYE, 'epoch');
    end
else
    epochDescriptions = p.Results.epochDescriptions;
end

if isempty(p.Results.rejectionThreshold)
    rejectionThreshold = str2double(inputdlg('Reject epochs with at least what percent missing data?'))/100;
else
    rejectionThreshold = p.Results.rejectionThreshold;
end

EYE = applyepochdescriptions(EYE, epochDescriptions, rejectionThreshold);

if isempty(p.Results.correctionType)
    correctionType = correctionOptions(...
        listdlg('PromptString', 'Baseline correction type',...
        'ListString', correctionOptions));
else
    correctionType = p.Results.correctionType;
end

[EYE.correctionType] = deal(correctionType);

if ~strcmp(correctionType, 'none')
    if ~exist('baselineDescriptions', 'var')
        if isempty(p.Results.baselineDescriptions)
            baselineDescriptions = UI_getspandescriptions(EYE, 'baseline');
        else
            baselineDescriptions = p.Results.baselineDescriptions;
        end
        
        if isempty(p.Results.epochsToCorrect)
            for bIdx = 1:numel(baselineDescriptions)
                baselineDescriptions(bIdx).epochsToCorrect = epochDescriptions(...
                    listdlg('PromptString', sprintf('Which epochs should be corrected using baseline %s', baselineDescriptions(bIdx).name),...
                        'ListString', {epochDescriptions.name})).name;
            end
        elseif ~strcmp(p.Results.epochsToCorrect, 'default')
            [baselineDescriptions.epochsToCorrect] = p.Results.epochsToCorrect{:};
        end
    end
    [EYE.baselineDescriptions] = deal(baselineDescriptions);
    EYE = baselinecorrection(EYE, baselineDescriptions, correctionType);
end

if ~isempty(p.Results.UI)
    p.Results.UI.UserData.EYE = EYE;
    p.Results.UI.Visible = 'off';
    p.Results.UI.Visible = 'on';
    writetopanel(p.Results.UI,...
        'processinghistory',...
        'Separation into epochs');
end

end