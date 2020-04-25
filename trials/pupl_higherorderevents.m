
function out = pupl_higherorderevents(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_higherorderevents(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
	'primary' [] % Selector for primary events
	'secondary' [] % Selector for secondary events
	'lims' [] % Window-defining time limits within which to look for secondary events; cell array of char arrays
	'relidx' [] % Relative indices of secondary events; numerical array
    'evar' [] % Event variable filter
	'presence' [] % Mark higher-order events by presence or absence of searched-for events; true or false
	'method' [] % What to do once a higher-order event has been found
    'cfg' [] % Configuration that controls the action taken once a higher-order event has been found
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.primary)
    args.primary = pupl_event_selUI(EYE, 'Which are the primary events?');
    if isempty(args.primary)
        return
    end
end

if isempty(args.secondary)
    args.secondary = pupl_event_selUI(EYE, 'Which are the secondary events?');
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

if isempty(args.evar)
    txt = {
        'Search for secondary events meeting some criterion defined by event variables?'
        'Input an expression that will return true if a secondary event has been found'
        'Event variables preceded by "#1" (e.g. #1rt) will be read from the primary event, those preceded by #2 will be read from the candidate secondary events'
        '(Leave empty to not use an event variable criterion)'
    };
    args.evar = inputdlg(sprintf('%s\n\n', txt{:}));
    if isempty(args.evar)
        return
    else
        args.evar = args.evar{:};
        if isempty(args.evar)
            args.evar = 0;
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
        'Add an event var to primary events'
    };
    sel = listdlgregexp(...
        'PromptString', 'What should be done when a higher-order event is found?',...
        'ListString', opts,...
        'SelectionMode', 'single',...
        'regexp', false);
    if isempty(sel)
        return
    end
    switch sel
        case 1
            args.method = 'rename';
        case 2
            args.method = 'evar';
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
        case 'evar'
            args.cfg.expr = inputdlg(sprintf('Input an expression to compute new event variable(s)\n\nEvent variables preceded by "#1" (e.g. #1rt) will be read from the primary event, those preceded by #2 will be read from the earliest secondary event found'));
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
            opts = {'numeric' 'string'};
            sel = listdlgregexp(...
                'PromptString', sprintf('What type of variable is\n#%s?', args.cfg.var),...
                'ListString', opts,...
                'SelectionMode', 'single',...
                'regexp', false);
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
primary_matches = pupl_event_sel(EYE.event, args.primary);
n_found = 0;
for pri_idx = find(primary_matches)
    pri_ev = EYE.event(pri_idx);
    sec_idx = pupl_event_sel(EYE.event, args.secondary);
    % Time window filter
    if ~isempty(tlims)
        primary_time = pri_ev.time;
        rel_times = [EYE.event.time] - primary_time; % Event times relative to primary
        sec_idx = sec_idx & ...
            rel_times >= tlims(1) &...
            rel_times <= tlims(2);
    end
    % Relative index filter
    if ~ischar(args.relidx)
        relinds = (1:numel(EYE.event)) - pri_idx;
        sec_idx = sec_idx &...
            ismember(relinds, args.relidx);
    end
    % Event variable filter
    if args.evar ~= 0
        evar_idx = pupl_evar_eval(args.evar, pri_ev, EYE.event(sec_idx));
        evar_idx = ~cellfun(@isempty, evar_idx) & cellfun(@all, evar_idx);
        % Convert evar_idx from an index relative to the already-found
        % secondary events to an index relative to the entire array of
        % events:
        prev_idx = find(sec_idx);
        evar_idx = prev_idx(evar_idx);
        new_idx = false(size(EYE.event));
        new_idx(evar_idx) = true;
        evar_idx = new_idx;
        sec_idx = sec_idx &...
            evar_idx;
    end
    sec_idx = find(sec_idx, 1);
    if args.presence == any(sec_idx)
        n_found = n_found + 1;
        switch args.method
            case 'rename'
                EYE.event(pri_idx).type = args.cfg.name;
            case 'evar'
                sec_ev = EYE.event(sec_idx);
                var = pupl_evar_get(args.cfg.expr, pri_ev, sec_ev);
                if ~ischar(var)
                    if strcmp(args.cfg.type, 'string')
                        var = num2str(var);
                        if exist('string', 'file') % Convert to string scalar if supported
                            var = string(var);
                        end
                    else
                        var = double(var);
                    end
                else
                    if strcmp(args.cfg.type, 'numeric')
                        var = str2double(var);
                    end
                end
                EYE.event(pri_idx).(args.cfg.var) = var;
        end
    end
end
fprintf('\t\t%d higher-order events found\n', n_found);

end