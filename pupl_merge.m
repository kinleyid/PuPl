function structArray = pupl_merge(EYE, varargin)

p = inputParser;
addParameter(p, 'UI', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

conditions = unique({EYE.cond});

if numel(unique(mergefields(EYE, 'srate'))) > 1
    uiwait(msgbox('Inconsistent sample rates'));
else
    srate = EYE(1).srate;
end

structArray = [];

for condIdx = 1:numel(conditions)
    condStruct = struct(...
        'name', conditions{condIdx},...
        'srate', srate,...
        'bin', []);
    currBins = mergefields(EYE(strcmpi({EYE.condition}, conditions{condIdx})), 'bin');
    binNames = unique({currBins.name});
    for binIdx = 1:numel(binNames)
        mergedBin = struct('name', binNames{binIdx},...
            'data', struct(...
                'left', [],...
                'right', [],...
                'both', []));
        currData = [currBins(strcmp({currBins.name}, binNames{binIdx})).data];
        for field = reshape(fieldnames(currData), 1, [])
            for dataIdx = 1:numel(currData)
                mergedBin.(field{:}) = cat(1,...
                    mergedBin.data.(field{:}),...
                    currData(dataIdx).(field{:}));
            end
        end
        condStruct.bin = cat(2, condStruct.bin, mergedBin);
    end
    structArray = [structArray condStruct];
end

if ~isempty(p.Results.UI)
    p.Results.UI.UserData.EYE = structArray;
    writetopanel(p.Results.UI, 'datasetinfo', {structArray.name}, 'overwrite');
    writetopanel(p.Results.UI, 'processinghistory', 'Condition merging');
end

end