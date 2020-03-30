
function out = pupl_higherorderevents(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_higherorderevents(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
	'primary' [] % Names of time-locking events; cell array of char arrays
	'secondary' [] % Names of events to search for near time-locking events; cell array of char arrays
	'lims' [] % Window-defining time limits within which to look for searched-for events; cell array of char arrays
	'relidx' [] % Relative indices of searched-for events; numerical array
	'presence' [] % Mark higher-order events by presence or absence of searched-for events; true or false
	'method' [] % What to do once a higher-order event has been found
    'cfg' [] % Configuration that controls the action taken once a higher-order event has been found
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.primary)
    args.primary = pupl_event_UIget([EYE.event], 'Which are the primary events?');
    if isempty(args.primary)
        return
    end
end

if isempty(args.secondary)
    args.secondary = pupl_event_UIget([EYE.event], 'Which are the secondary events?');
    if isempty(args.secondary)
        return
    end
end

if isempty(args.lims)
    args.lims = inputdlg(...
        {
            sprintf('Search for secondary events within this time window relative to primary events\n(Leave empty to not use a time window)\n\nStart')
            'End'
        });
    if isempty(args.lims)
        return
    elseif all(cellfun(@isempty, args.lims))
        args.lims = 'none';
    end
end
args.lims = cellstr(args.lims);

if isempty(args.relidx)
    args.relidx = inputdlg(...
        sprintf('Search for secondary events occurring at these indices relative to primary events\n(Leave empty to not use relative indices)'));
    if isempty(args.relidx)
        return
    else
        args.relidx = str2num(args.relidx{:});
        if isempty(args.relidx)
            args.relidx = 'none';
        end
    end
end

if isempty(args.presence)
    q = 'Check for presence or absence of secondary events?';
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

if isempty(args.method)
    opts = {
        'Rename primary events'
        'Add a trial var to primary events'
    };
    sel = listdlg(...
        'PromptString', 'What should be done when a higher-order event is found?',...
        'ListString', opts,...
        'SelectionMode', 'single');
    switch sel
        case 1
            args.method = 'rename';
        case 2
            args.method = 'tvar';
        otherwise
            return
    end
end

if isempty(args.cfg)
    switch args.method
        case 'rename'
            args.cfg.name = inputdlg('What should the primary events be renamed to?');
            if isempty(args.cfg.name)
                return
            else
                args.cfg.name = args.cfg.name{:};
            end
        case 'tvar'
            args.cfg.expr = inputdlg(sprintf('Input an expression to compute new trial variable(s)\n\nTrial variables preceded by "#1" (e.g. #1rt) will be read from the primary event, those preceded by #2 will be read from the earliest secondary event found'));
            if isempty(args.cfg.expr)
                return
            else
                args.cfg.expr = args.cfg.expr{:};
            end
            args.cfg.var = inputdlg('Name of resulting variable');
            if isempty(args.cfg.var)
                return
            else
                args.cfg.var = args.cfg.var{:};
                args.cfg.var = regexprep(args.cfg.var, '#', '');
            end
            opts = {'Numeric' 'String'};
            sel = listdlg(...
                'PromptString', sprintf('What type of variable is #%s?', args.cfg.var),...
                'ListString', opts,...
                'SelectionMode', 'single');
            if isempty(sel)
                return
            else
                args.cfg.type = opts(sel);
            end
    end
end

outargs = args;

end

function EYE = sub_higherorderevents(EYE, varargin)

args = parseargs(varargin{:});

if ~strcmp([args.lims{:}], 'none')
    tlims = parsetimestr(args.lims, EYE.srate);
else
    tlims = [];
end
primary_idx = pupl_event_sel(EYE.event, args.primary);
n_found = 0;
for eventidx = find(primary_idx)
    pri_ev = EYE.event(eventidx);
    windowidx = true(size(EYE.event));
    if ~isempty(tlims)
        primary_time = EYE.event(eventidx).time;
        rel_times = [EYE.event.time] - primary_time; % Event times relative to primary
        windowidx = windowidx & ...
            rel_times >= tlims(1) &...
            rel_times <= tlims(2);
    end
    if ~ischar(args.relidx)
        relinds = (1:numel(EYE.event)) - eventidx;
        windowidx = windowidx &...
            ismember(relinds, args.relidx);
    end
    found = pupl_event_sel(EYE.event(windowidx), args.secondary);
    if args.presence == any(found)
        n_found = n_found + 1;
        switch args.method
            case 'rename'
                EYE.event(eventidx).type = args.cfg.name;
            case 'tvar'
                sec_ev = EYE.event(windowidx);
                sec_ev = sec_ev(find(found, 1)); % In case there are multiple events found
                var = pupl_tvar_get(args.cfg.expr, pri_ev, sec_ev);
                if isnumeric(var)
                    if strcmp(args.cfg.type, 'String')
                        var = num2str(var);
                    end
                elseif isstr(var)
                    if strcmp(args.cfg.type, 'Numeric')
                        var = str2num(var);
                    end
                end
                EYE.event(eventidx).(args.cfg.var) = var;
        end
    end
end
fprintf('\t\t%d higher-order events found\n', n_found);

end