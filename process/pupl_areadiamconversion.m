
function pupl_areadiamconversion(EYE, getwhich)

switch getwhich
    case 'diam'
        EYE = arrayfun(@(x) structfun(@(y) pi / 4 * y .^ 2, x), EYE);
    case 'area'
        EYE = arrayfun(@(x) structfun(@(y) sqrt(2 * y) / pi, x), EYE);
end

callstr = sprintf('eyeData = %m(eyeData, %s)', mfilename, getwhich);

end