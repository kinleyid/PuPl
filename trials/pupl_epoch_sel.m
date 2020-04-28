
function idx = pupl_epoch_sel(EYE, epoch_selector)
% Epoch selector
%
% Inputs:
%   EYE: struct
%       eye data (single struct, not array)
%   epoch_selector: struct
%       see pupl_epoch_selector

% Input check
if numel(EYE) > 1
    error('%s only works on single structs, not arrays', mfilename);
end

idx = true(size(EYE.epoch));
if ~isempty(epoch_selector)
    
    timelocking_events = pupl_epoch_get(EYE, [], '_tl');
    
    if isfield(epoch_selector, 'type')
        % Select by epoch type
        idx = idx & ismember({EYE.epoch.name}, epoch_selector.type);
    end
    
    if isfield(epoch_selector, 'set')
        % Select by epoch set name (basically a shortcut)
        for set_idx = find(ismember({EYE.epochset.name}, epoch_selector.set))
            idx = idx & pupl_event_sel(timelocking_events, EYE.epochset(set_idx).members);
        end
    end
    
    if isfield(epoch_selector, 'filt')
        % Select by event filter
        idx = idx & pupl_event_sel(timelocking_events, epoch_selector.filt);
    end
    
    if isfield(epoch_selector, 'idx')
        % Select by index
        tmp = false(size(idx));
        tmp(epoch_selector.idx) = true;
        idx = idx & tmp;
    end
    
end

end
