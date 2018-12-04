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
addParameter(p, 'baselineDescriptions', []);
addParameter(p, 'epochsToCorrect', []);
addParameter(p, 'correctionType', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

if isempty(p.Results.epochDescriptions)
    q = sprintf('Simple epoching?\n(All epochs of same length and\ndefined using single events)');
    if strcmp(questdlg(q, q, 'Yes', 'No', 'Yes'), 'Yes')
        eventTypes = unique(mergefields(EYE, 'event', 'type'));
        eventTypes = eventTypes(listdlgregexp('PromptString', 'Epoch relative to which events?',...
            'ListString', eventTypes));
        if isempty(eventTypes)
            return
        end
        epochLims = (inputdlg(...
            {sprintf('''s'' = 1 sample\nE.g. 10 + s = 10 seconds plus one sample\n\nEpochs start this many seconds relative to events:')
            'Epochs end at this many seconds relative to events:'}));
        if isempty(epochLims)
            return
        end
        baselineLims = (inputdlg(...
            {sprintf('''s'' = 1 sample\nE.g. 10 + s = 10 seconds plus one sample\n\nBaselines start this many seconds relative to events:')
            'Baselines end at this many seconds relative to events:'}));
        if isempty(baselineLims)
            return
        end
        [epochDescriptions, baselineDescriptions] = deal(struct([]));
        for eventTypeIdx = 1:numel(eventTypes)
            epochDescriptions = cat(2, epochDescriptions,...
                struct('name', eventTypes{eventTypeIdx},...
                    'lims', struct(...
                        'event', eventTypes{eventTypeIdx},...
                        'instance', 0,...
                        'bookend', {epochLims{1} epochLims{2}})));
            baselineDescriptions = cat(2, baselineDescriptions,...
                struct('name', eventTypes{eventTypeIdx},...
                    'lims', struct(...
                        'event', eventTypes{eventTypeIdx},...
                        'instance', 0,...
                        'bookend', {baselineLims{1} baselineLims{2}})));
        end
        [baselineDescriptions.epochsToCorrect] = epochDescriptions.name;
    else
        epochDescriptions = UI_getspandescriptions(EYE, 'epoch');
    end
else
    epochDescriptions = p.Results.epochDescriptions;
end

EYE = applyepochdescriptions(EYE, epochDescriptions);

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

end