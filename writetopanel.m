function writetopanel(UI, tag, txt)

txt = reshape(cellstr(txt), [], 1);

panelIdx = strcmpi(tag, arrayfun(@(x) x.Tag, UI.Children, 'un', 0));

if strcmp('', UI.Children(panelIdx).Children(1).Value(1))
    UI.Children(panelIdx).Children(1).Value = sprintf('1. %s', txt{1});
    txt(1) = [];
end
for i = 1:numel(txt)
    UI.Children(panelIdx).Children(1).Value = cat(1,...
        UI.Children(panelIdx).Children(1).Value,...
        sprintf('%d. %s', numel(UI.Children(panelIdx).Children(1).Value)+1, txt{i}));
end