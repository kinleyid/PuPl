
function printable_cell = pupl_event_selprint(selector)
% Print event selector in a nice way

switch selector.by
    case 'idx'
        if ischar(selector.sel)
            sel = selector.sel;
        else
            sel = all2str(selector.sel);
        end
        printable_cell = {
            sprintf('event numbers %s', sel);
        };
    case 'regexp'
        printable_cell = {
            sprintf('events matching the regular expression "%s"', selector.sel);
        };
    case 'evar'
        printable_cell = {
            sprintf('events meeting the following criterion: "%s"', selector.sel);
        };
end

end