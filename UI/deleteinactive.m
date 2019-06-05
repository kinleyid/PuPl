function deleteinactive(dataType)

global userInterface

UserData = get(userInterface, 'UserData');
switch dataType
    case 'eye data'
        global eyeData
        dots = repmat({' '}, 1, numel(eyeData));
        dots(UserData.activeEyeDataIdx) = {'>'};
        [~, currIdx] = listdlg(...
            'ListString', strcat(dots, {eyeData.name}),...
            'PromptString', 'Remove which?');
        % currIdx = ~UserData.activeEyeDataIdx;
        for currData = reshape(eyeData(currIdx), 1, [])
            fprintf('Removing %s\n', currData.name);
        end
        eyeData(currIdx) = [];
        UserData.activeEyeDataIdx(currIdx) = [];
    case 'event logs'
        global eventLogs
        currIdx = ~UserData.activeEventLogsIdx;
        for currData = reshape(eventLogs(currIdx), 1, [])
            fprintf('Removing %s\n', currData.name);
        end
        eventLogs(currIdx) = [];
        UserData.activeEventLogsIdx(currIdx) = [];
end

set(userInterface, 'UserData', UserData);

end