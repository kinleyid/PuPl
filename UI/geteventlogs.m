function out = geteventlogs

global eventLogs userInterface
out = eventLogs(userInterface.UserData.activeEyeDataIdx);

end