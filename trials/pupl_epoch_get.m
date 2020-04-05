
function out = pupl_epoch_get(EYE, epochs, ctrl, varargin)

if numel(EYE) > 1
    out = [];
    for dataidx = 1:numel(EYE)
        out = [out pupl_epoch_get(EYE(dataidx), epochs, ctrl, varargin{:})];
    end
else
    if isempty(epochs)
        epochs = EYE.epoch; % All epochs
    elseif ~isstruct(epochs)
        epochs = EYE.epoch(epochs); % Index
    end

    switch ctrl
        case '_ev' % Get events
            event_ids = [EYE.event.uniqid];
            idx = nan(1, numel(epochs));
            for epochidx = 1:numel(epochs)
                idx(epochidx) = find(event_ids == epochs(epochidx).event);
            end
            out = EYE.event(idx);
        case '_lat' % Get event latencies
            out = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epochs, '_ev'), varargin{:});
        otherwise % Get a field from sthe events
            events = pupl_epoch_get(EYE, epochs, '_ev');
            out = mergefields(events, ctrl);
    end
end

end