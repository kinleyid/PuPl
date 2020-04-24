
function out = pupl_epoch_get(EYE, sel, varargin)
% Get attributes of epochs
%
% Inputs:
%   sel
%       [] <- select all epochs
%       cell array <- selector (see pupl_epoch_sel)
%       index <- numerical or logical index
%       string <- name of epoch set
%   ctrl
%       attribute to get
if numel(varargin) == 0
    ctrl = '_'; % Get epochs themselves
else
    ctrl = varargin{1};
end
extra_args = varargin(2:end);
if numel(EYE) > 1
    out = [];
    for dataidx = 1:numel(EYE)
        out = [out pupl_epoch_get(EYE(dataidx), sel, ctrl, extra_args{:})];
    end
else
    % From here on, EYE is a single struct
    if isempty(sel)
        % Select all epochs
        sel = true(size(EYE.epoch));
    elseif isstr(sel)
        % Epoch set name
        epochset = EYE.epochset(strcmp({EYE.epochset.name}, sel));
        sel = epochset.members;
    end
    
    if iscell(sel)
        sel = find(pupl_epoch_sel(EYE, [], sel));
    end
    
    if ~isstruct(sel)
        epochs = EYE.epoch(sel); % Index, logical or numeric
    else
        epochs = sel;
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
            lims = parsetimestr([epochs.lims], getfield(EYE, extra_args{:}, 'srate'), 'smp');
            lims = reshape(lims, 2, [])';
            lats = nan(numel(epochs), 2);
            lats(:, 1) = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epochs, '_tl'), extra_args{:});
            lats(:, 2) = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epochs, '_o'), extra_args{:});
            is_bef = strcmp(mergefields(epochs, 'other', 'when'), 'before');
            lats(is_bef, :) = fliplr(lats(is_bef, :));
            out = lats + lims;
        case {'_rel' '_rellats'}
            abslats = pupl_epoch_get(EYE, epochs, '_abslats', extra_args{:});
            t1_lats = pupl_epoch_get(EYE, epochs, '_lat', extra_args{:});
            out = bsxfun(@minus, abslats, t1_lats(:));
        case '_lat' % Get timelocking event latencies
            out = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epochs, '_tl'), extra_args{:});
        case 'name'
            % Some epochs may have their own names
            out = {epochs.name};
            num_idx = cellfun(@isnumeric, out);
            if any(num_idx)
                events = pupl_epoch_get(EYE, epochs(num_idx), '_tl');
                out(num_idx) = {events.name};
            end
        case '_units'
            out = pupl_epoch_units(epochs);
        case '_'
            out = epochs;
        otherwise % Get a field from the events
            events = pupl_epoch_get(EYE, epochs, '_tl');
            out = mergefields(events, ctrl);
    end
end

end