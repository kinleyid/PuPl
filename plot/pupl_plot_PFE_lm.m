function pupl_plot_PFE_lm(h, EYE, ax, varargin)

if numel(varargin) > 0
    a = varargin{1};
else
    a = 0.1;
end

x = EYE.gaze.(ax);
axes(h); hold on;
y = mergelr(EYE);
s = scatter(x, y, 5, 'k', 'filled');
try
    alpha(s, a); % Doesn't work in Octave
end
B = nanlm(y, EYE.gaze.x, EYE.gaze.y);
line_x = [min(x) max(x)];
switch ax
    case 'x'
        line_y = B(1) + line_x * B(2) + nanmean_bc(EYE.gaze.y(:)) * B(3);
    case 'y'
        line_y = B(1) + nanmean_bc(EYE.gaze.x(:)) * B(2) + line_x * B(3);
end
plot(line_x, line_y, 'r');

xlabel(sprintf('Gaze %s (%s, %s)', EYE.units.gaze.(ax){:}));
ylabel(sprintf('Pupil %s (%s, %s)', EYE.units.pupil{:}));

end