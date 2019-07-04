function EYE = definehigherorderevents(EYE, varargin)

p = inputParser;
addParameter(p, 'name', []); % Name of higher-order event; char array
addParameter(p, 'timelocking', []); % Names of time-locking events; cell array of char arrays
addParameter(p, 'checkfor', []); % Names of events to search for near time-locking events; cell array of char arrays
addParameter(p, 'lims', []); % Window-defining time limits within which to look for searched-for events; cell array of char arrays
addParameter(p, 'relindices', []); % Relative indices of searched-for events; numerical array
addParameter(p, 'presence', []); % Mark higher-order events by presence or absence of searched-for events; true or false
addParameter(p, 'overwrite', []); % Overwrite pre-existing time-locking events; true or false
parse(p, varargin{:});
if isempty(p.Results.name)
    name = inputdlg('Name of higher-order event');
    if isempty(name)
        return
    end
else
    name = p.Results.name;
end
if iscell(name)
    name = [name{:}];
end

if isempty(p.Results.timelocking)
    [~, timelocking] = listdlgregexp(...
        'PromptString', 'What are the time-locking events?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')));
    if isempty(timelocking)
        return
    end
else
    timelocking = p.Results.timelocking;
end
timelocking = cellstr(timelocking);

if isempty(p.Results.checkfor)
    [~, checkfor] = listdlgregexp(...
        'PromptString', 'Search for which events?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')));
else
    checkfor = p.Results.checkfor;
end
checkfor = cellstr(checkfor);

if isempty(p.Results.lims)
    lims = inputdlg(...
        {
            sprintf('Search for events within this time window relative to time-locking events\n(Leave empty to not use a time window)\n\nStart')
            'End'
        });
    if isempty(lims)
        return
    elseif all(cellfun(@isempty, lims))
        lims = 'none';
    end
else
    lims = p.Results.lims;
end
lims = cellstr(lims);

if isempty(p.Results.relindices)
    relindices = inputdlg(...
        sprintf('Search for events occurring at these indices relative to time-locking events\n(Leave empty to not use relative indices)'));
    if isempty(relindices)
        return
    else
        relindices = str2num(relindices{:});
    end
else
    relindices = p.Results.relindices;
end

if isempty(p.Results.presence)
    q = 'Mark by presence or absence of searched-for events?';
    a = questdlg(q, q, 'Presence', 'Absence', 'Cancel', 'Presence');
    switch a
        case 'Presence'
            presence = true;
        case 'Absence'
            presence = false;
        otherwise
            return
    end
else
    presence = p.Results.presence;
end
presence = logical(presence);

if isempty(p.Results.overwrite)
    q = 'Overwrite time-locking events?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
    switch a
        case 'Yes'
            overwrite = true;
        case 'No'
            overwrite = false;
        otherwise
            return
    end
else
    overwrite = p.Results.overwrite;
end
overwrite = logical(overwrite);

callstr = getcallstr(p);

fprintf('Defining higher-order events...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    if ~strcmp([lims{:}], 'none')
        currlims = timestr2lat(EYE(dataidx), lims);
    else
        currlims = [];
    end
    tlockidx = ismember({EYE(dataidx).event.type}, timelocking);
    foundidx = false(size(EYE(dataidx).event));
    for eventidx = find(tlockidx)
        windowidx = true(size(EYE(dataidx).event));
        if ~isempty(currlims)
            tlock = EYE(dataidx).event(eventidx).latency;
            rellats = [EYE(dataidx).event.latency] - tlock;
            windowidx = windowidx & ...
                rellats >= currlims(1) &...
                rellats <= currlims(2);
        end
        if ~isempty(relindices)
            relinds = (1:numel(EYE(dataidx).event)) - eventidx;
            windowidx = windowidx &...
                ismember(relinds, relindices);
        end
        if presence == any(ismember({EYE(dataidx).event(windowidx).type}, checkfor))
            foundidx(eventidx) = true;
        end
    end
    fprintf('%d higher-order events defined\n', nnz(foundidx));
    newEvents = EYE(dataidx).event(foundidx);
    [newEvents.type] = deal(name);
    if overwrite
        EYE(dataidx).event(foundidx) = [];
    end
    EYE(dataidx).event = cat(2, EYE(dataidx).event(:)', newEvents);
    [~, I] = sort([EYE(dataidx).event.latency]);
    EYE(dataidx).event = EYE(dataidx).event(I);
    EYE(dataidx).history{end+1} = callstr;
end
fprintf('Done\n');

end