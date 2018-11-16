function EYE = interpeyedata(EYE, varargin)

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

for dataIdx = 1:numel(EYE)
    EYE(dataIdx).data.left = applyinterpolation(EYE(dataIdx).data.left);
    EYE(dataIdx).data.right = applyinterpolation(EYE(dataIdx).data.right);
end

end

function v = applyinterpolation(v)

v(isnan(v)) = interp1(find(~isnan(v)), v(~isnan(v)), find(isnan(v)) );

end