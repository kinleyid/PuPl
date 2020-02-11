function savewarning(varargin)

global pupl_globals

if ~isempty(pupl_globals) % will be empty if clear('all') happened
    unsaved_data = evalin('base', pupl_globals.datavarname);
    if ~isempty(unsaved_data)
        a = questdlg(sprintf('Save data (variable "%s") from workspace?', pupl_globals.datavarname));
        if strcmpi(a, 'yes')
            batch = false;
            if numel(unsaved_data) > 1
                a = questdlg('Save all data in the same folder?');
                if strcmpi(a, 'yes')
                    batch = true;
                end
            end
            pupl_save(unsaved_data, 'batch', batch);
        end
    end
end

delete(gcbf)

end