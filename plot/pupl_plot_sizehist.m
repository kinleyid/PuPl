
function pupl_plot_sizehist(f, EYE)

% Plot a histogram of gap durations
eye_names = fieldnames(EYE.pupil);
n_eyes = numel(eye_names);
data = cell(1, n_eyes);
for eye_idx = 1:n_eyes
    data{eye_idx} = EYE.pupil.(eye_names{eye_idx});
    data{eye_idx} = data{eye_idx}(:)';
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
xlabel(pupl_getunits(EYE))
ylabel('Data count')
legend(h, eye_names{:});

end
