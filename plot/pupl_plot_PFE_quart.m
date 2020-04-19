function pupl_plot_PFE_quart(h, EYE, ax)

x = EYE.gaze.(ax);
axes(h); hold on;
y = mergelr(EYE);
s = scatter(x, y, 5, 'k', 'filled');
try
    alpha(s, 1 / 10 / log10(nnz(~isnan(y) & ~isnan(y)))); % Doesn't work in Octave
end
set(s, 'HandleVisibility', 'off');
line_x = linspace(min(EYE.gaze.x), max(EYE.gaze.x), 1000);
[p1, p2, cutoff] = PFE_quart(x, y);
line_y = nan(size(line_x));
p1_idx = line_x < cutoff;
p2_idx = line_x >= cutoff;
line_y(p1_idx) = polyval(p1, line_x(p1_idx));
line_y(p2_idx) = polyval(p2, line_x(p2_idx));
plot(line_x, line_y, 'r');

xlabel(sprintf('Gaze %s (%s, %s)', EYE.units.gaze.(ax){:}));
ylabel(sprintf('Pupil %s (%s, %s)', EYE.units.pupil{:}));

plot([cutoff cutoff], [min(y) max(y)], 'r:');

legend('Best-fitting quartic function', 'Split between piecewise functions');

end