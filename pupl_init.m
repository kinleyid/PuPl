
global userInterface

if isgraphics(userInterface)
    q = 'Re-initializing will delete any unsaved data. Continue?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        return
    end
    close(userInterface)
end

global eyeData eventLogs activeIdx
[eyeData, eventLogs, activeIdx] = deal([]);
pupl_UI