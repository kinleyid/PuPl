
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
        case {'_ev' '_tl'} % Get timelocking events
            event_ids = [EYE.event.uniqid];
            idx = nan(1, numel(epochs));
            for epochidx = 1:numel(epochs)
                idx(epochidx) = find(event_ids == epochs(epochidx).event);
            end
            out = EYE.event(idx);
        case '_o' % Get non-timelocking events
            event_ids = [EYE.event.uniqid];
            idx = nan(1, numel(epochs));
            for epochidx = 1:numel(epochs)
                idx(epochidx) = find(event_ids == epochs(epochidx).other.event);
            end
            out = EYE.event(idx);
        case {'_abs' '_abslats'}
            lims = parsetimestr([epochs.lims], getfield(EYE, varargin{:}, 'srate'), 'smp');
            lims = reshape(lims, 2, [])';
            lats = nan(numel(epochs), 2);
            lats(:, 1) = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epochs, '_tl'), varargin{:});
            lats(:, 2) = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epochs, '_o'), varargin{:});
            is_bef = strcmp(mergefields(epochs, 'other', 'when'), 'before');
            lats(is_bef, :) = fliplr(lats(is_bef, :));
            out = lats + lims;
        case {'_rel' '_rellats'}
            abslats = pupl_epoch_get(EYE, epochs, '_abslats', varargin{:});
            t1_lats = pupl_epoch_get(EYE, epochs, '_lat', varargin{:});
            out = bsxfun(@minus, abslats, t1_lats(:));
        case '_lat' % Get timelocking event latencies
            out = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epochs, '_tl'), varargin{:});
        otherwise % Get a field from the events
            events = pupl_epoch_get(EYE, epochs, '_tl');
            out = mergefields(events, ctrl);
    end
end

end