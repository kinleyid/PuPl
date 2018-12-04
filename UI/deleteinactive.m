function deleteinactive(dataType)

global userInterface

switch dataType
    case 'eye data'
        global eyeData
        currIdx = ~userInterface.UserData.activeEyeDataIdx;
        for currData = reshape(eyeData(currIdx), 1, [])
            fprintf('Removing %s\n', currData.name);
        end
        eyeData(currIdx) = [];
        userInterface.UserData.activeEyeDataIdx(currIdx) = [];
    case 'event logs'
        global eventLogs
        currIdx = ~userInterface.UserData.activeEventLogsIdx;
        for currData = reshape(eventLogs(currIdx), 1, [])
            fprintf('Removing %s\n', currData.name);
        end
        eventLogs(currIdx) = [];
        userInterface.UserData.activeEventLogsIdx(currIdx) = [];
end

end