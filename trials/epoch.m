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

if any(arrayfun(@(x) ~isempty(x.epoch), EYE))
    q = 'Overwrite existing trials?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
    switch a
        case 'Yes'
            [EYE.epoch] = deal([]);
        case 'No'
        otherwise
            return
    end
end

if isempty(p.Results.epochDescriptions)
    q = sprintf('Simple epoching?\n(All epochs of same length and\ndefined using single events)');
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
    switch a
        case 'Yes'
            eventTypes = unique(mergefields(EYE, 'event', 'type'));
            eventTypes = eventTypes(listdlgregexp('PromptString', 'Epoch relative to which events?',...
                'ListString', eventTypes));
            if isempty(eventTypes)
                return
            end
            epochLims = (inputdlg(...
                {sprintf('Trials start at this time relative to events:')
                'Trials end at this time relative to events:'}));
            if isempty(epochLims)
                return
            else
                fprintf('Trials defined from [event] + %s to [event] + %s\n', epochLims{:})
            end
            baselineLims = (inputdlg(...
                {sprintf('Baselines start at this time relative to events:')
                'Baselines end at this time relative to events:'}));
            if isempty(baselineLims)
                fprintf('Cancelling\n')
                return
            else
                fprintf('Baselines defined from [event] + %s to [event] + %s\n', baselineLims{:})
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
        case 'No'
            epochDescriptions = UI_getspandescriptions(EYE, 'epoch');
            if isempty(epochDescriptions)
                return
            end
        otherwise
            return
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