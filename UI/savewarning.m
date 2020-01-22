function savewarning(varargin)

global pupl_globals
unsaved_data = evalin('base', pupl_globals.datavarname);

if ~isempty(unsaved_data)
    q = sprintf('Save data (variable %s) from workspace?', pupl_globals.datavarname);
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
    switch a
        case 'Yes'
            if numel(unsaved_data) > 1
                batch = true;
            else
                batch = false;
            end
            pupl_save('data', unsaved_data, 'type', 'eye data', 'batch', batch);
            delete(gcbf)
        case 'No'
            delete(gcbf)
    end
else
    delete(gcbf)
end

end