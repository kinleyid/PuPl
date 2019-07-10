function EYE = unreject(EYE)

fprintf('Unrejecting trials...\n')
for dataIdx = 1:numel(EYE)
    fprintf('\t%s: %d trials un-rejected\n', EYE(dataIdx).name, nnz([EYE(dataIdx).epoch.reject]))
    [EYE(dataIdx).epoch.reject] = deal(false);
end

fprintf('Done\n')

end