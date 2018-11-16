function EYE = mergelr(EYE, varargin)

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

if ~isempty(p.Results.UI)
    fprintf('Merging left and right streams...');
end

for dataIdx = 1:numel(EYE)
    fprintf('dataset %d...', dataIdx)
    EYE(dataIdx).data.both = mean([
        EYE(dataIdx).data.left
        EYE(dataIdx).data.right], 1);
end

end