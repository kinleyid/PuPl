
function pupl_PFE_surface(a, EYE, varargin)

ngrid = 32;
boxcar = 0.5;

[surface, density, x, y] = compute_surface(EYE, ngrid, boxcar);

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
    cbarLabel = sprintf('Average pupil %s (%s, %s)', EYE.units.pupil{:});
end
set(gca, 'YDir', 'normal');
xlabel(sprintf('Gaze %s (%s, %s)', EYE.units.gaze.x{:});
ylabel(sprintf('Gaze %s (%s, %s)', EYE.units.gaze.y{:});
c = colorbar;
l = get(c, 'Label');
set(l, 'String', cbarLabel);

end

function [surface, xgrid, ygrid] = compute_surface(EYE, ngrid, boxcar)

xgrid = linspace(min(EYE.gaze.x), max(EYE.gaze.x), ngrid);
ygrid = linspace(min(EYE.gaze.y), max(EYE.gaze.y), ngrid);

xwidth = (xgrid(2) - xgrid(1)) * boxcar;
ywidth = (ygrid(2) - ygrid(1)) * boxcar;

data = mergelr(EYE);

idx = false(numel(xgrid), numel(ygrid), numel(data));

surface = nan(size(idx, 1), size(idx, 2));
for xi = 1:numel(xgrid)
    for yi = 1:numel(ygrid)
        curridx =  abs(EYE.gaze.x - xgrid(xi)) <= xwidth...
            & abs(EYE.gaze.y - ygrid(yi)) <= ywidth;
        surface(yi, xi) = nanmean_bc(data(curridx));
    end
end

xgrid = ranges.x;
ygrid = ranges.y;

end