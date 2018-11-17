function EYE = interpeyedata(EYE, varargin)

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

fprintf('Interpolating\n')
for dataIdx = 1:numel(EYE)
    fprintf('%s...', EYE(dataIdx).name)
    for field = reshape(fieldnames(EYE(dataIdx).data), 1, [])
        EYE(dataIdx).data.(field{:}) = applyinterpolation(EYE(dataIdx).data.(field{:}));
    end
    fprintf('done\n')
end

end

function v = applyinterpolation(v)

v(isnan(v)) = interp1(find(~isnan(v)), v(~isnan(v)), find(isnan(v)) );

end