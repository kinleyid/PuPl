function update_UI

% For when new data is loaded or the active datasets change

global userInterface eyeData eventLogs
activeEventLogsIdx = userInterface.UserData.activeEventLogsIdx;
activeEyeDataPanel = findobj(userInterface, 'Tag', 'activeEyeDataPanel');
activeEventLogsPanel = findobj(userInterface, 'Tag', 'activeEventLogsPanel');

if userInterface.UserData.dataCount ~= numel(eyeData) || userInterface.UserData.eventLogCount ~= numel(eventLogs)
    % Data added or deleted
    userInterface.UserData.dataCount = numel(eyeData);
    userInterface.UserData.eventLogCount = numel(eventLogs);
    preservelayout
end

for i = 1:numel(activeEyeDataPanel.Children)
    userInterface.UserData.activeEyeDataIdx(numel(activeEyeDataPanel.Children) + 1 - i) = ...
        logical(activeEyeDataPanel.Children(i).Value);
end

for i = 1:numel(activeEventLogsPanel.Children)
    userInterface.UserData.activeEventLogsIdx(numel(activeEventLogsPanel.Children) + 1 - i) = ...
        logical(activeEventLogsPanel.Children(i).Value);
end

userInterface.Visible = 'off';
userInterface.Visible = 'on';

end