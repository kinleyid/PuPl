
function event_lats = pupl_event_getlat(EYE, sel, varargin)

if isempty(varargin)
    ctrl = 'idx';
else
    ctrl = varargin{1}; % idx, t, or uniqid
end

if isstruct(sel)
    % Struct array of events has been provided as input
    event_times = [sel.time];
else
    switch ctrl
        case 'idx'
            % Index
            event_times = [EYE.event(sel).time];
        case 't'
            event_times = sel;
            %{
        case 'uniqid'
            event_times = [EYE.event(ismember(sel, [EYE.event.uniqid])).time];
            %}
    end
end
sample_times = EYE.times;
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