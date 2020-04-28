
function event_lats = pupl_event_getlat(EYE, sel, varargin)
% Get latency of event

sample_times = getfield(EYE, varargin{:}, 'times');

if isstruct(sel)
    % Struct array of events has been provided as input
    event_times = [sel.time];
else
    event_times = [EYE.event(sel).time];
end
event_lats = nan(size(event_times));
last_lat = 1;
nt = numel(event_times);
for tidx = 1:nt
    [~, curr_lat] = min(abs(sample_times(last_lat:end) - event_times(tidx)));
    curr_lat = curr_lat + last_lat - 1;
    last_lat = curr_lat;
    event_lats(tidx) = curr_lat;
end

end