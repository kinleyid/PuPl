
fprintf('Version 0.00.00.1\n');

global userInterface

if isgraphics(userInterface)
    close(userInterface)
end

fprintf('Initializing global variables...\n')
global eyeData eventLogs activeEyeDataIdx activeEventLogsIdx
[eyeData, eventLogs, activeEyeDataIdx, activeEventLogsIdx] = deal([]);
activeEyeDataIdx = logical(activeEyeDataIdx);
activeEventLogsIdx = logical(activeEventLogsIdx);

pupl_UI