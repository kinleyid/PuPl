
global userInterface

if isgraphics(userInterface)
    close(userInterface)
end

global eyeData eventLogs activeEyeDataIdx activeEventLogsIdx
[eyeData, eventLogs, activeEyeDataIdx, activeEventLogsIdx] = deal([]);
activeEyeDataIdx = logical(activeEyeDataIdx);
pupl_UI