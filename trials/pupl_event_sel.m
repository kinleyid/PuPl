
function idx = pupl_event_sel(events, filter)

if ischar(filter) % Just one event name
    filter = {filter};
end

num_idx = cellfun(@isnumeric, filter);
if ~any(num_idx)
    indic = 0;
else
    indic = filter{num_idx};
end
filter = filter(~num_idx);
switch indic
    case 0 % Select by name
        idx = ismember({events.name}, filter);
    case 1 % Select by regular expression applied to name
        idx = ~cellfun(@isempty, regexp({events.name}, filter{:}));
    case 2 % Select by trial var filter
        try
            ret = pupl_evar_eval(filter{:}, events);
            idx = ~cellfun(@isempty, ret) & cellfun(@all, ret);
        catch
            idx = false(size(events)); % This is just to avoid callback weirdness
        end
end

end
