
function [sample_times, event_times, event_lats] = processtimestamps(sample_times, event_times, srate)

sp = 1000/srate;
% Set first timestamp to 0
t1 = sample_times(1);
event_times(event_times < t1) = t1;
% Cut inter-trial gaps
gaps = find(diff(sample_times) > sp);
for gap_start = gaps
    next_t_x = sample_times(gap_start) + sp; % Expected
    next_t_a = sample_times(gap_start + 1); % Actual
    % Reset inter-trial event times to the timestamp of the first sample of
    % the next trial:
    event_times(event_times >= next_t_x & event_times <= next_t_a) = next_t_x;
    % Subtract the inter-trial interval from the subsequent timestamps
    ITI = next_t_x - next_t_a;
    sample_times(gap_start + 1:end) = sample_times(gap_start + 1:end) - ITI;
    event_times(event_times > next_t_a) = event_times(event_times > next_t_a) - ITI;
end
event_times(event_times > sample_times(end)) = sample_times(end);

end