
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
        path = '';
        for dataidx = 1:numel(EYE)
            [file, path] = uigetfile(sprintf('%s*', path), sprintf('Event log for %s', EYE(dataidx).name));
            if file == 0
                return
            end
            fullpath = sprintf('%s', path, file);
            fprintf('Attaching %s to %s\n', file, EYE(dataidx).name);
            eventlog = feval(loadfunc, fullpath);
            eventlog.src = fullpath;
            EYE(dataidx).eventlog = eventlog;
        end
        fprintf('Done\n');
    otherwise
        return
end

end
