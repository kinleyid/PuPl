function EYE = unreject(EYE)

for dataIdx = 1:numel(EYE)
    fprintf('%s: %d trials un-rejected\n', EYE(dataIdx).name, nnz([EYE(dataIdx).epoch.reject]))
    [EYE(dataIdx).epoch.reject] = deal(false);
end

end