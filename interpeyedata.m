function EYE = interpeyedata(EYE)

for dataIdx = 1:numel(EYE)
    EYE.data.left = applyinterpolation(EYE.data.left);
    EYE.data.right = applyinterpolation(EYE.data.right);
end

end

function v = applyinterpolation(v)

v(isnan(v)) = interp1(find(~isnan(v)), v(~isnan(v)), find(isnan(v)) );

end