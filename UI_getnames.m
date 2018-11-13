function newNames = UI_getnames(oldNames)

oldNames = cellstr(oldNames);
nOptsPerScreen = 10;

newNames = {};

for i = 1:nOptsPerScreen:length(oldNames)
    currNames = oldNames(i:min(length(oldNames), i+nOptsPerScreen-1));
    currNames = inputdlg(currNames,...
        'Which names should be used?',...
        [1 100],...
        currNames);
    newNames = cat(1, newNames(:), currNames(:));
end

end