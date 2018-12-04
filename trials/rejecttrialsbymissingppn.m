function EYE = rejecttrialsbymissingppn(EYE, varargin)

%   Inputs
% EYE--struct array
%   Outputs
% EYE--struct array

p = inputParser;
addParameter(p, 'threshold', []);
parse(p, varargin{:});

if isempty(p.Results.threshold)
    threshold = UI_getrejectionthreshold(EYE);
else
    threshold = p.Results.threshold;
end

fprintf('Rejecting trials with >= %0.1f%% missing data...\n', threshold*100);

missingPpns = getmissingppns(EYE);

for dataIdx = numel(EYE)
    for epochIdx = 1:numel(EYE(dataIdx).epoch)
        if missingPpns{dataIdx}(epochIdx) >= threshold
            EYE(dataIdx).epoch(epochIdx).reject = true;
        end
    end
    fprintf('%s: %d/%d trials rejected\n',...
        EYE(dataIdx).name,...
        nnz(missingPpns{dataIdx} >= threshold),...
        numel(EYE(dataIdx).epoch));
end

end