function void = deleteactive(dataType)

void = [];

global userInterface

if strcmpi(dataType, 'eye data')
    global eyeData
    for currData = reshape(eyeData(userInterface.UserData.activeEyeDataIdx), 1, [])
        fprintf('Removing %s\n', currData.name);
    end
    eyeData(userInterface.UserData.activeEyeDataIdx) = [];
    userInterface.UserData.activeEyeDataIdx(userInterface.UserData.activeEyeDataIdx) = [];
elseif strcmpi(dataType, 'event logs')
    global eventLogs
    for currData = reshape(eventLogs(userInterface.UserData.activeEventLogsIdx), 1, [])
        fprintf('Removing %s\n', currData.name);
    end
    eventLogs(userInterface.UserData.activeEventLogsIdx) = [];
    userInterface.UserData.activeEventLogsIdx(userInterface.UserData.activeEventLogsIdx) = [];
end

end