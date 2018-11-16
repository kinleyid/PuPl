
global userInterface

if isgraphics(userInterface)
    q = 'Re-initializing will delete any unsaved data. Continue?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        clear q a
        return
    end
    clear q a
    close(userInterface)
end

global eyeData eventLogs activeEyeDataIdx activeEventLogsIdx
[eyeData, eventLogs, activeEyeDataIdx, activeEventLogsIdx] = deal([]);
activeEyeDataIdx = logical(activeEyeDataIdx);
pupl_UI