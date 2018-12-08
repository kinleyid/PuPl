function [surface, density, x, y] = computePFEsurface(EYE, gridN, trimPpn, inputRange, boxcar)

if isempty(inputRange)
    sorteds = structfun(@(v) sort(v(~isnan(v))), EYE.gaze, 'un', 0);
    ranges = structfun(@(v)...
                linspace(v(max(round(trimPpn*numel(v)), 1)),...
                         v(min(round((1 - trimPpn)*numel(v)), numel(v))),...
                         gridN),...
        sorteds, 'un', 0);
else
    ranges = struct(...
        'x', linspace(inputRange(1), inputRange(2), gridN),...
        'y', linspace(inputRange(3), inputRange(4), gridN));
end
widths = structfun(@(x) (x(2) - x(1))*boxcar, ranges, 'un', 0);

idx = false(numel(ranges.x), numel(ranges.y), numel(EYE.data.left));

[surface, density] = deal(nan(size(idx,1), size(idx,2)));for xi = 1:numel(ranges.x)
    for yi = 1:numel(ranges.y)
        currIdx =  abs(EYE.gaze.x - ranges.x(xi)) <= widths.x...
            & abs(EYE.gaze.y - ranges.y(yi)) <= widths.y...
            & ~EYE.isBlink;
        surface(yi, xi) = mean(EYE.data.left(currIdx), 'omitnan');
        density(yi, xi) = nnz(~isnan(EYE.data.left(currIdx)));
    end
end

x = ranges.x;
y = ranges.y;

end