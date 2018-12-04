function savewarning(varargin)

global eyeData eventLogs
if ~isempty(eyeData) || ~isempty(eventLogs)
    q = 'Save data from workspace?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');

    switch a
        case 'Yes'
            data = {eyeData eventLogs};
            types = {'eye data' 'event logs'};
            for i = 1:numel(data)
                if ~isempty(data{i})
                    uiwait(msgbox(sprintf('Save the %s', types{i})));
                    pupl_save('data', data{i}, 'type', types{i});
                end
            end
            delete(gcbf)
        case 'No'
            delete(gcbf)
    end
else
    delete(gcbf)
end

end