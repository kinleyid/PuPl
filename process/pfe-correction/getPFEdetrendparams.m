function params = getPFEdetrendparams(EYE, ax)

x = reshape(EYE.gaze.(ax), [], 1);
y = reshape(mergelr(EYE), [], 1);

badIdx = isnan(x) | isnan(y);

switch ax
    case 'y'
        n = 1;
    case 'x'
        n = 2;
end
params = polyfit(x(~badIdx), y(~badIdx), n);

end