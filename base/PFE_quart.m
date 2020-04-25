
function [p1, p2, cutoff, yhat] = PFE_quart(x, y)

y = y(:);
x = x(:);
% Boxcar smooth y values to identify peak
x_lims = linspace(min(x), max(x), 101);
n_smoothed = numel(x_lims) - 1;
y_smoothed = nan(1, n_smoothed);
for idx = 1:n_smoothed
    y_smoothed(idx) = nanmean_bc(...
        y(...
            x >= x_lims(idx) &...
            x < x_lims(idx + 1)...
        )...
    );
end
[~, I] = max(y_smoothed);
cutoff = mean([x_lims(I) x_lims(I + 1)]);

badidx = isnan(x) | isnan(y);
y_good = y(~badidx);
x_good = x(~badidx);
% Fit separate quartic functions for either side
p1_idx_good = x_good < cutoff;
p2_idx_good = x_good >= cutoff;
p1 = polyfit(x_good(p1_idx_good), y_good(p1_idx_good), 4);
p2 = polyfit(x_good(p2_idx_good), y_good(p2_idx_good), 4);

yhat = y;
p1_idx = x < cutoff;
p2_idx = x >= cutoff;
yhat(p1_idx) = polyval(p1, x(p1_idx));
yhat(p2_idx) = polyval(p2, x(p2_idx));

end