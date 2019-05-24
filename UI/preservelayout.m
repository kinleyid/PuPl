function preservelayout(varargin)

sep = 2;
buttonHeight = 20;

global userInterface eyeData

currData = eyeData;
currPanel = getcomponentbytag(userInterface, 'activeEyeDataPanel');
activeIdx = userInterface.UserData.activeEyeDataIdx;
if ~isempty(currPanel.Children)
    delete(currPanel.Children)
end
activeIdx(numel(activeIdx)+1:numel(currData)) = true;
bgPos = getpixelposition(currPanel);
top = bgPos(4) - buttonHeight;
buttonWidth = bgPos(3) - sep;
for i = 1:numel(currData)
    if activeIdx(i)
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

userInterface.UserData.activeEyeDataIdx = activeIdx;

end