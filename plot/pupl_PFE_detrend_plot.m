function pupl_PFE_detrend_plot(h, EYE, ax, varargin)

if numel(varargin) > 0
    a = varargin{1};
else
    a = 0.1;
end

params = pupl_PFE_detrend_getparams(EYE, ax);

x = EYE.gaze.(ax);
axes(h); hold on;
s = scatter(x, mergelr(EYE), 5, 'k', 'filled');
try
    alpha(s, a); % Doesn't work in Octave
end
linex = sort(x);
liney = polyval(params, linex);
plot(linex, liney, 'k');

xlabel(sprintf('Gaze %s (%s, %s)', EYE.units.gaze.(ax){:}));
ylabel(sprintf('Pupil %s (%s, %s)', EYE.units.pupil{:}));

end