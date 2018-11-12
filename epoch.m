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
parse(p, varargin{:});

if isempty(p.Results.epochDescriptions)
    epochDescriptions = UI_getspandescriptions(EYE);
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
    if isempty(p.Results.baselineDescriptions)
        baselineDescriptions = UI_getspandescriptions(EYE);
    else
        baselineDescriptions = p.Results.baselineDescriptions;
    end

    if isempty(p.Results.epochsToCorrect)
        epochsToCorrect = {};
        for bIdx = 1:numel(baselineDescriptions)
            baselineDescriptions(bIdx).epochsToCorrect = epochDescriptions(...
                listdlg('PromptString', sprintf('Which epochs should be corrected using baseline %s', baselineDescriptions(bIdx).name),...
                    'ListString', {epochDescriptions.name})).name;
        end
    elseif ~strcmp(p.Results.epochsToCorrect, 'default')
        [baselineDescriptions.epochsToCorrect] = p.Results.epochsToCorrect{:};
    end
    [EYE.baselineDescriptions] = deal(baselineDescriptions);
    EYE = baselinecorrection(EYE, baselineDescriptions, correctionType);
end

end