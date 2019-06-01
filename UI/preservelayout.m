function preservelayout(varargin)

sep = 2;
buttonHeight = 20;

global userInterface eyeData

currData = eyeData;
currPanel = findobj('tag', 'activeEyeDataPanel');
activeIdx = getfield(get(userInterface, 'UserData'), 'activeEyeDataIdx');
if ~isempty(get(currPanel, 'Children'))
    % delete(currPanel.Children);
    set(currPanel, 'Children', []);
end
activeIdx(numel(activeIdx)+1:numel(currData)) = true;
% bgPos = getpixelposition(currPanel);
bgPos = get(userInterface, 'position') .* get(currPanel, 'position');
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

UserData = get(userInterface, 'UserData');
UserData.activeEyeDataIdx = activeIdx;
set(userInterface, 'UserData', UserData);

end