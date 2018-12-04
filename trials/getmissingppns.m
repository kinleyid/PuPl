function ppns = getmissingppns(EYE)

%   Inputs
% EYE--struct array
%   Outputs
% ppns--cell vector of numerical vectors

ppns = cell(1, numel(EYE));
for dataIdx = 1:numel(EYE)
    currPpns = nan(1, numel(EYE(dataIdx).epoch));
    for epochIdx = 1:numel(currPpns)
        currLats = EYE(dataIdx).epoch(epochIdx).latencies;
        amtMissing = ...
            nnz(isnan(EYE(dataIdx).urData.left(currLats))) +...
            nnz(isnan(EYE(dataIdx).urData.right(currLats)));
        currPpns(epochIdx) = amtMissing/(2*numel(currLats));
    end
    ppns{dataIdx} = currPpns;
end

end