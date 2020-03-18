
function idx = pupl_event_sel(events, filter)

num_idx = cellfun(@isnumeric, filter);
if ~any(num_idx)
    indic = 0;
else
    indic = filter{num_idx};
end
filter = filter(~num_idx);
switch indic
    case 0 % Select by name
        idx = ismember({events.type}, filter);
    case 1 % Select by regular expression applied to name
        idx = ~cellfun(@isempty, regexp({events.type}, filter{:}));
    case 2 % Select by trial var filter
        idx = false(size(events));
        for eidx = 1:numel(events)
            if eval(regexprep(filter{:}, '#', 'events(eidx).var.'))
                idx(eidx) = true;
            end
        end
end

end
