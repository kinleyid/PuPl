
function pupl_PFE_surface(a, EYE, varargin)

ngrid = 32;
boxcar = 0.5;

any_data = EYE.ppnmissing < 1;
if any_data
    [surface, x_grid, y_grid, counts] = compute_surface(EYE, ngrid, boxcar);
else
    surface = nan;
    x_grid = 0;
    y_grid = 0;
    counts = nan;
end

axes(a);
if any(strcmpi(varargin, 'density'))
    % DEPRECATED
    title('Measured dilation by gaze coordinates')
    image(x_grid, y_grid, density,...
        'CDataMapping', 'scaled');
    cbarLabel = 'N. data points';
elseif any(strcmpi(varargin, 'error'))
    title('Measured dilation by gaze coordinates')
    im = image(x_grid, y_grid, surface,...
        'CDataMapping', 'scaled');
    try
        log_counts = log(counts + 1);
        scaled_counts = log_counts / max(log_counts(:));
        % set(im, 'AlphaDataMapping', 'scaled');
        set(im, 'AlphaData', scaled_counts);
    end
    cbarLabel = sprintf('Average pupil %s (%s, %s)', EYE.units.pupil{:});
end
set(gca, 'YDir', 'normal');
xlabel(sprintf('Gaze %s (%s, %s)', EYE.units.gaze.x{:}));
ylabel(sprintf('Gaze %s (%s, %s)', EYE.units.gaze.y{:}));
c = colorbar;
l = get(c, 'Label');
set(l, 'String', cbarLabel);

if ~any_data
    warndlg(sprintf('No data for %s', EYE.name), 'No data!');
end

end

function [surface, xgrid, ygrid, counts] = compute_surface(EYE, ngrid, boxcar)

xgrid = linspace(min(EYE.gaze.x), max(EYE.gaze.x), ngrid);
ygrid = linspace(min(EYE.gaze.y), max(EYE.gaze.y), ngrid);

xwidth = (xgrid(2) - xgrid(1)) * boxcar;
ywidth = (ygrid(2) - ygrid(1)) * boxcar;

data = mergelr(EYE);

idx = false(numel(xgrid), numel(ygrid), numel(data));

surface = nan(size(idx, 1), size(idx, 2));
counts = nan(size(idx, 1), size(idx, 2));
for xi = 1:numel(xgrid)
    for yi = 1:numel(ygrid)
        curridx =  abs(EYE.gaze.x - xgrid(xi)) <= xwidth...
            & abs(EYE.gaze.y - ygrid(yi)) <= ywidth;
        surface(yi, xi) = nanmean_bc(data(curridx));
        counts(yi, xi) = numel(data(curridx));
    end
end

end