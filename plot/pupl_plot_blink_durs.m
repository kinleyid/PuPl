
function pupl_plot_blink_durs(f, EYE)

% Plot a histogram of blink durations

db = diff([0 EYE.datalabel == 'b' 0]);
blink_starts = find(db == 1);
blink_ends = find(db == -1);
blink_durs = blink_ends - blink_starts; % in samples
d = blink_durs / EYE.srate * 1000; % in ms

axes(f); hold on;
if isempty(d)
    c = 10;
else
    n = 4*log2(numel(d));
    x1 = min(d);
    x2 = max(d);
    c = [x1:(x2-x1)/(n-1):x2 x2+(x2-x1)/(n-1)];
end
hist(d, c);
h = findobj(gca, 'Type', 'patch');
set(h, 'EdgeColor', 'w');
set(h, 'FaceColor', [0.5 0.5 0.5]);
% Get rid of little starts along the x axis
set(findobj(gca, 'Type', 'line'), 'Marker', 'none');
% Set displayed x to be strictly positive
curr_xlim = xlim;
xlim([0 curr_xlim(2)]);
xlabel('Blink duration (ms)')
ylabel('Count')

end