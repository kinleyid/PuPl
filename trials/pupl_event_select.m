
function idx = pupl_event_select(events, selector)
% Select events based on an event selector
% 
% Inputs:
%   events: struct
%       structure array of events with name, time, and event variables
%   selector: struct
%       struct with fields "by" and "sel", produced by pupl_UI_event_select
% Output:
%   idx: logical array
%       logical indices of selected epochs

idx = false(size(events));
if ~isempty(selector.sel)
    switch selector.by
        case 'idx'
            if ~ischar(selector.sel)
                sel = all2str(selector.sel);
            else
                sel = selector.sel;
            end
            eval(sprintf('idx([%s]) = true;', sel));
        case 'regexp'
            idx = ~cellfun(@isempty, regexp({events.name}, selector.sel));
        case 'evar' 
            try
                ret = pupl_evar_eval(selector.sel, events);
                idx = ~cellfun(@isempty, ret) & cellfun(@all, ret);
            catch
                idx = false(size(events)); % This is just to avoid callback weirdness
            end
    end
end
end