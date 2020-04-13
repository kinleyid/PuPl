
function printable_cell = pupl_event_selprint(filter)

% Print selector in a nice way

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
        printable_cell = filter;
    case 1 % Select by regular expression applied to name
        printable_cell = {
            sprintf('"%s" (regular expression)', filter{:});
        };
    case 2 % Select by trial var filter
        printable_cell = {
            sprintf('"%s" (event variable criterion)', filter{:});
        };
end

end