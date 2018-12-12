function ppns = getmissingppns(EYE)

%   Inputs
% EYE--struct array
%   Outputs
% ppns--cell vector of numerical vectors

ppns = cell(1, numel(EYE));
for dataIdx = 1:numel(EYE)
    currPpns = nan(1, numel(EYE(dataIdx).epoch));
    for epochIdx = 1:numel(currPpns)
        isMissing = isnan([
            EYE(dataIdx).epoch(epochIdx).diam.left
            EYE(dataIdx).epoch(epochIdx).diam.right]);
        currPpns(epochIdx) = nnz(isMissing)/numel(isMissing);
    end
    ppns{dataIdx} = currPpns;
end

end