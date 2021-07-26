
function out = pupl_epoch_get(EYE, epoch_selector, varargin)
% Get attributes of epochs
%
% Inputs:
%   epoch_selector: struct or cell
%       if struct: a structure to select epochs (see pupl_epoch_selector)
%       if cell: a cell containing the epochs themselves
%   varargin{1}: string
%       attribute to get (if empty, get epochs themselves)
%   varargin{2}: optional string
%       'ur', if computing latency based on undownsampled sample times
if numel(varargin) == 0
    ctrl = '_'; % Get epochs themselves
else
    ctrl = varargin{1};
end
maybe_ur = varargin(2:end);
if numel(EYE) > 1
    out = [];
    for dataidx = 1:numel(EYE)
        out = [out pupl_epoch_get(EYE(dataidx), epoch_selector, ctrl, maybe_ur{:})];
    end
else
    % From here on, EYE is a single struct
    
    % get epochs
    if iscell(epoch_selector)
        epochs = epoch_selector{:};
    else
        epochs = EYE.epoch(pupl_epoch_sel(EYE, epoch_selector));
    end
    
    switch ctrl
        case {'_tl' '_ev'} % Get timelocking events
            [~, idx] = ismember([epochs.event], [EYE.event.uniqid]);
            out = EYE.event(idx);
        case '_o' % Get non-timelocking events
            [~, idx] = ismember(mergefields(epochs, 'other', 'event'), [EYE.event.uniqid]);
            out = EYE.event(idx);
        case {'_abs' '_abslats'}
            lims = parsetimestr([epochs.lims], getfield(EYE, maybe_ur{:}, 'srate'), 'smp');
            lims = reshape(lims, 2, [])';
            lats = nan(numel(epochs), 2);
            lats(:, 1) = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epoch_selector, '_tl'), maybe_ur{:});
            lats(:, 2) = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epoch_selector, '_o'), maybe_ur{:});
            is_bef = strcmp(mergefields(epochs, 'other', 'when'), 'before');
            lats(is_bef, :) = fliplr(lats(is_bef, :));
            out = lats + lims;
        case {'_rel' '_rellats'}
            abslats = pupl_epoch_get(EYE, epoch_selector, '_abslats', maybe_ur{:});
            tl_lats = pupl_epoch_get(EYE, epoch_selector, '_lat', maybe_ur{:});
            out = bsxfun(@minus, abslats, tl_lats(:));
        case '_lat' % Get timelocking event latencies
            out = pupl_event_getlat(EYE, pupl_epoch_get(EYE, epoch_selector, '_tl'), maybe_ur{:});
        case {'_name' '_type'}
            % Some epochs may have their own names
            out = {epochs.name};
        case '_units'
            out = pupl_epoch_units(epochs);
        case '_'
            out = epochs;
        case {'_base' '_baseline'}
            if isfield(epochs, 'baseline')
                out = [epochs.baseline];
            else
                out = [];
            end
        otherwise % Get a field from the events
            events = pupl_epoch_get(EYE, epoch_selector, '_tl');
            out = mergefields(events, ctrl);
    end
end

end