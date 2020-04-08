
function pupl_event_view(h, EYE)

listbox_contents = cell(size(EYE.event));

for idx = 1:numel(EYE.event)
    listbox_contents{idx} = sprintf('%d. [%fs]: %s', idx, EYE.event(idx).time, EYE.event(idx).name);
end

lb = uicontrol(h,...
    'Style', 'listbox',...
    'String', listbox_contents,...
    'Max', inf,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.98]);

end