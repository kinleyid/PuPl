function PFEplot(a, EYE, varargin)

gridN = 32;
trimPpn = 0;
boxcar = 0.5;

[surface, density, x, y] = computePFEsurface(EYE, gridN, trimPpn, [], boxcar);

axes(a);
if any(strcmpi(varargin, 'density'))
    title('Measured dilation by gaze coordinates')
    image(x, y, density,...
        'CDataMapping', 'scaled');
    cbarLabel = 'N. data points';
elseif any(strcmpi(varargin, 'error'))
    title('Measured dilation by gaze coordinates')
    im = image(x, y, surface,...
        'CDataMapping', 'scaled');
    try
        set(im, 'AlphaData', ~isnan(surface))
    end
    cbarLabel = 'Average measured pupil diameter';
end
set(gca, 'YDir', 'normal');
xlabel('Gaze x');
ylabel('Gaze y');
c = colorbar;
l = get(c, 'Label');
set(l, 'String', cbarLabel);

end