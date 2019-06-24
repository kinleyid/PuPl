
function plotPFEtrend(h, EYE, ax, varargin)

if numel(varargin) > 0
    a = varargin{1};
else
    a = 0.1;
end

params = getPFEdetrendparams(EYE, ax);

x = EYE.gaze.(ax);
axes(h); hold on;
s = scatter(x, mergelr(EYE), 5, 'k', 'filled');
try
    alpha(s, a);
end
linex = sort(x);
liney = polyval(params, linex);
plot(linex, liney, 'k');

xlabel(['Gaze ' ax]);
ylabel('Pupil diameter');

end