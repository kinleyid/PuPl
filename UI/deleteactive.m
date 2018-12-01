function deleteactive(dataType)

global userInterface

switch dataType
    case 'eye data'
        global eyeData
        for currData = reshape(eyeData(userInterface.UserData.activeEyeDataIdx), 1, [])
            fprintf('Removing %s\n', currData.name);
        end
        eyeData(userInterface.UserData.activeEyeDataIdx) = [];
        userInterface.UserData.activeEyeDataIdx(userInterface.UserData.activeEyeDataIdx) = [];
    case 'event logs'
        global eventLogs
        for currData = reshape(eventLogs(userInterface.UserData.activeEventLogsIdx), 1, [])
            fprintf('Removing %s\n', currData.name);
        end
        eventLogs(userInterface.UserData.activeEventLogsIdx) = [];
        userInterface.UserData.activeEventLogsIdx(userInterface.UserData.activeEventLogsIdx) = [];
end

end