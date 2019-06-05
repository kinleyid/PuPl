function PFEplot(EYE, varargin)

if numel(EYE) > 1
    EYE = EYE(listdlg('PromptString', 'Plot from which dataset?',...
        'ListString', {EYE.name}));
end

p = inputParser;
addParameter(p, 'gridN', []);
addParameter(p, 'trimPpn', []);
addParameter(p, 'boxCar', []);
parse(p, varargin{:});

if any(structfun(@isempty, p.Results))
    params = cellfun(@str2double,...
        inputdlg({'Trim what proportion of the highest and lowest x and y gaze values?',...
            'Divide the gaze field into an n-by-n grid where n equals:',...
            'Boxcar square side length (in units of grid points)'},...
            'PFEplot params',...
            [1 70],...
            {'0.15' '32'  '2'}),...
        'un', 0);
    if isempty(params)
        return
    else
        [trimPpn, gridN, boxCar] = params{:};
    end
else
    gridN = p.Results.gridN;
    trimPpn = p.Results.trimPpn;
    boxCar = p.Results.boxCar;
end

% Trim percentages
sorteds = structfun(@(v) sort(v(~isnan(v))), EYE.gaze, 'un', 0);
ranges = structfun(@(v)...
            linspace(v(max(round(trimPpn*numel(v)), 1)),...
                     v(min(round((1 - trimPpn)*numel(v)), numel(v))),...
                     gridN),...
    sorteds, 'un', 0);
widths = structfun(@(x) (x(2) - x(1))*boxCar, ranges, 'un', 0);

[averages, densities] = deal(nan(gridN));

if isfield(EYE.data, 'both')
    dataVector = EYE.data.both;
else
    dataVector = nanmean_bc([EYE.data.left; EYE.data.right]);
end

for xi = 1:numel(ranges.x)
    for yi = 1:numel(ranges.y)
        currIdx = abs(EYE.gaze.x - ranges.x(xi)) <= widths.x...
            & abs(EYE.gaze.y - ranges.y(yi)) <= widths.y...
            & ~EYE.isBlink;
        averages(yi, xi) = nanmean_bc(dataVector(currIdx));
        densities(yi, xi) = nnz(currIdx);
    end
end

figure('ToolBar', 'none',...
    'MenuBar', 'none',...
    'Color', [1 1 1],...
    'NumberTitle', 'off',...
    'Name', 'Pupil foreshortening error surface');
im = image(ranges.x, ranges.y, averages, 'CDataMapping', 'scaled');
% set(im, 'AlphaData', (densities/max(densities(:))).^(1/8));
set(im, 'AlphaData', ~isnan(averages));
xlabel('Gaze x');
ylabel('Gaze y');
title('Measured dilation by gaze coordinates')
c = colorbar;
c.Label.String = 'Average measured dilation';

end