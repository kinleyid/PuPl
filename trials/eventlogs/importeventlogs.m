
function EYE = importeventlogs(EYE, loadfunc)

% loadfunc is a handle to a function that takes a full path and return an
% event log struct

q = 'Load BIDS raw data?';
a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
switch a
    case 'Yes'
        rawdatapath = uigetdir(pwd, 'Select raw data folder');
        if isnumeric(rawdatapath)
            return
        end
        eventlogs = importBIDSraw(rawdatapath, loadfunc, '_events.', false);
        % Assign eventlogs to eye data
        for dataidx = 1:numel(eventlogs)
            idx = strcmp(eventlogs(dataidx).name, {EYE.name});
            EYE(idx).eventlog = eventlogs(dataidx);
        end
    case 'No'
        currpath = '';
        fullpaths = cell(1, numel(EYE));
        for dataidx = 1:numel(EYE)
            [file, currpath] = uigetfile(sprintf('%s*', currpath), sprintf('Event log for %s', EYE(dataidx).name));
            if file == 0
                return
            end
            fullpath = sprintf('%s', currpath, file);
            fprintf('Attaching [[%s]] to [[%s]]...', file, EYE(dataidx).name);
            eventlog = loadfunc(fullpath);
            eventlog.src = fullpath;
            EYE(dataidx).eventlog = eventlog;
            fprintf('done\n');
        end
        for dataidx = 1:numel(EYE)
            
        end
        fprintf('\nDone\n');
    otherwise
        return
end

end
