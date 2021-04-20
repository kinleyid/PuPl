
function pupl_plot_gap_durs(f, EYE)

% Plot a histogram of gap durations
eye_names = fieldnames(EYE.pupil);
n_eyes = numel(eye_names);
data = cell(1, n_eyes);
for eye_idx = 1:n_eyes
    db = diff([0 isnan(EYE.pupil.(eye_names{eye_idx})) 0]);
    blink_starts = find(db == 1);
    blink_ends = find(db == -1);
    blink_durs = blink_ends - blink_starts; % in samples
    data{eye_idx} = blink_durs / EYE.srate * 1000; % in ms
end

a = 0.4;
axes(f); hold on;
d = [data{:}];
n = 4*log2(numel(d));
x1 = min(d);
x2 = max(d);
c = [x1:(x2-x1)/(n-1):x2 x2+(x2-x1)/(n-1)];
if any(isnan(c))
    % All data is missing
    c = 10;
end
for eye_n = 1:n_eyes
    hist(data{eye_n}, c);
end
h = findobj(gca, 'Type', 'patch');
colours = {[1 0 0] [0 0 1]}; % Red and blue
for hist_idx = 1:n_eyes
    set(h(hist_idx), 'FaceColor', colours{hist_idx});
end
set(h, 'EdgeColor', 'w');
try
    alpha(h, a);
end
% Get rid of little starts along the x axis
set(findobj(gca, 'Type', 'line'), 'Marker', 'none');
xlabel('Gap duration')
ylabel('Data count')
legend(h, eye_names{:});

end