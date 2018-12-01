function preservelayout(varargin)

sep = 2;
buttonHeight = 20;

global userInterface eyeData eventLogs

allData = {
    eyeData
    eventLogs};
allPanels = {
    getcomponentbytag(userInterface, 'activeEyeDataPanel')
    getcomponentbytag(userInterface, 'activeEventLogsPanel')};
allActiveIdx = {
    userInterface.UserData.activeEyeDataIdx
    userInterface.UserData.activeEventLogsIdx};

for idx = 1:numel(allData)
    currData = allData{idx};
    currPanel = allPanels{idx};
    currActiveIdx = allActiveIdx{idx};
    if ~isempty(currPanel.Children)
        delete(currPanel.Children)
    end
    currActiveIdx(numel(currActiveIdx)+1:numel(currData)) = true;
    bgPos = getpixelposition(currPanel);
    top = bgPos(4) - buttonHeight;
    buttonWidth = bgPos(3) - sep;
    for i = 1:numel(currData)
        if currActiveIdx(i)
            value = 1;
        else
            value = 0;
        end
        uicontrol(currPanel,...
            'Style', 'checkbox',...
            'Position', [sep, top - (buttonHeight+sep)*i, buttonWidth, buttonHeight],...
            'String', currData(i).name,...
            'Value', value,...
            'FontSize', 10,...
            'Callback', @(h, e) update_UI);
    end
end

end