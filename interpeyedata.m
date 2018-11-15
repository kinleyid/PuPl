function EYE = interpeyedata(EYE, varargin)

p = inputParser;
addParameter(p, 'UI', []);
parse(p, varargin{:});

for dataIdx = 1:numel(EYE)
    EYE(dataIdx).data.left = applyinterpolation(EYE(dataIdx).data.left);
    EYE(dataIdx).data.right = applyinterpolation(EYE(dataIdx).data.right);
end

if ~isempty(p.Results.UI)
    p.Results.UI.UserData.EYE = EYE;
    writetopanel(p.Results.UI,...
        'processinghistory',...
        'Interpolation');
end

end

function v = applyinterpolation(v)

v(isnan(v)) = interp1(find(~isnan(v)), v(~isnan(v)), find(isnan(v)) );

end