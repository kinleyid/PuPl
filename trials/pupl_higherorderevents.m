
function out = pupl_higherorderevents(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_higherorderevents(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'name' [] % Name of higher-order event; char array
	'timelocking' [] % Names of time-locking events; cell array of char arrays
	'checkfor' [] % Names of events to search for near time-locking events; cell array of char arrays
	'lims' [] % Window-defining time limits within which to look for searched-for events; cell array of char arrays
	'relindices' [] % Relative indices of searched-for events; numerical array
	'presence' [] % Mark higher-order events by presence or absence of searched-for events; true or false
	'overwrite' [] % Overwrite pre-existing time-locking events; true or false
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.name)
    args.name = inputdlg('Name of higher-order event');
    if isempty(args.name)
        return
    else
        args.name = args.name{:};
    end
end

if isempty(args.timelocking)
    [sel, args.timelocking] = listdlgregexp(...
        'PromptString', 'What are the time-locking events?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')),...
        'AllowRegexp', true);
    if isempty(sel)
        return
    end
end

if isempty(args.checkfor)
    [sel, args.checkfor] = listdlgregexp(...
        'PromptString', 'Search for which events?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')),...
        'AllowRegexp', true);
    if isempty(sel)
        return
    end
end

if isempty(args.lims)
    args.lims = inputdlg(...
        {
            sprintf('Search for events within this time window relative to time-locking events\n(Leave empty to not use a time window)\n\nStart')
            'End'
        });
    if isempty(args.lims)
        return
    elseif all(cellfun(@isempty, args.lims))
        args.lims = 'none';
    end
end
args.lims = cellstr(args.lims);

if isempty(args.relindices)
    args.relindices = inputdlg(...
        sprintf('Search for events occurring at these indices relative to time-locking events\n(Leave empty to not use relative indices)'));
    if isempty(args.relindices)
        return
    else
        args.relindices = str2num(args.relindices{:});
        if isempty(args.relindices)
            args.relindices = 'none';
        end
    end
end

if isempty(args.presence)
    q = 'Mark by presence or absence of searched-for events?';
    a = questdlg(q, q, 'Presence', 'Absence', 'Cancel', 'Presence');
    switch a
        case 'Presence'
            args.presence = true;
        case 'Absence'
            args.presence = false;
        otherwise
            return
    end
end
args.presence = logical(args.presence);

if isempty(args.overwrite)
    q = 'Overwrite time-locking events?';
    a = questdlg(q);
    switch a
        case 'Yes'
            args.overwrite = true;
        case 'No'
            args.overwrite = false;
        otherwise
            return
    end
end
args.overwrite = logical(args.overwrite);

outargs = args;

end

function EYE = sub_higherorderevents(EYE, varargin)

args = parseargs(varargin{:});

if ~strcmp([args.lims{:}], 'none')
    currlims = parsetimestr(args.lims, EYE.srate, 'smp');
else
    currlims = [];
end
tlockidx = regexpsel({EYE.event.type}, args.timelocking);
foundidx = false(size(EYE.event));
for eventidx = find(tlockidx)
    windowidx = true(size(EYE.event));
    if ~isempty(currlims)
        tlock = EYE.event(eventidx).latency;
        rellats = [EYE.event.latency] - tlock;
        windowidx = windowidx & ...
            rellats >= currlims(1) &...
            rellats <= currlims(2);
    end
    if ~ischar(args.relindices)
        relinds = (1:numel(EYE.event)) - eventidx;
        windowidx = windowidx &...
            ismember(relinds, args.relindices);
    end
    if args.presence == any(regexpsel({EYE.event(windowidx).type}, args.checkfor))
        foundidx(eventidx) = true;
    end
end
fprintf('\t\t%d higher-order events defined\n', nnz(foundidx));
newnames = repmat(cellstr(args.name), 1, nnz(foundidx));
if ~args.overwrite
    newnames = strcat({EYE.event(foundidx).type}, newnames);
end
[EYE.event(foundidx).type] = newnames{:};

end