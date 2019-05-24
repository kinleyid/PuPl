
function EYE = importeventlogs(EYE, loadfunc)

% loadfunc is a handle to a function that takes a full path and return an
% event log struct

path = '';
for dataidx = 1:numel(EYE)
    [file, path] = uigetfile(sprintf('%s*', path), sprintf('Event log for %s', EYE(dataidx).name));
    if file == 0
        return
    end
    fullpath = sprintf('%s', path, file);
    fprintf('Attaching %s to %s\n', file, EYE(dataidx).name);
    EYE(dataidx).eventlog = feval(loadfunc, fullpath);
end
fprintf('Done\n');

end
