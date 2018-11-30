function savewarning(varargin)

global eyeData eventLogs
if ~isempty(eyeData) || ~isempty(eventLogs)
    q = 'Save data from workspace?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');

    if strcmp(a, 'Yes')
        data = {eyeData eventLogs};
        types = {'eye data' 'event logs'};
        for i = 1:numel(data)
            if ~isempty(data{i})
                pupl_save('data', data{i}, 'type', types{i});
            end
        end
    end
end

end