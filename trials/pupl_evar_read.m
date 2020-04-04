
function out = pupl_evar_read(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_evar_read(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'method' []
    'sel' []
    'expr' []
    'var' []
    'type' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.method)
    opts = {'Regexp capture from event name' 'Based on other event variables'};
        sel = listdlg(...
            'PromptString', sprintf('How do you want to define a new event variable?'),...
            'ListString', opts,...
            'SelectionMode', 'single');
        if isempty(sel)
            return
        else
            switch sel
                case 1
                    args.method = 're';
                case 2
                    args.method = 'evar';
                otherwise
                    return
            end
        end
end

if isempty(args.sel)
    args.sel = pupl_event_UIget([EYE.event], 'Add event variables to which events?');
    if isempty(args.sel)
        return
    end
end

if isempty(args.expr)
    switch args.method
        case 're'
            q = 'Input regular expression capture';
        case 'evar'
            q = sprintf('Write an expression that will return the new event variable\n\nVariables preceded by "#" (e.g. "#rt") will interpreted as event variables to be read from the event to which a new event variable is being added.');
    end
    args.expr = inputdlg(q);
    if isempty(args.expr)
        return
    else
        args.expr = args.expr{:};
    end
end

if isempty(args.var)
    switch args.method
        case 're'
            q = 'Variable names (separated by semicolons or commas)';
        case 'evar'
            q = 'Variable name';
    end
    args.var = inputdlg(q);
    if isempty(args.var)
        return
    else
        args.var = regexprep(args.var{:}, ' ', ''); % Remove whitespace
        args.var = regexprep(args.var, '#', ''); % Remove hash symbols (they'll be put back later)
        args.var = regexp(args.var, '[;,]', 'split'); % Split by semicolon or comma
    end
end

if isempty(args.type)
    for idx = 1:numel(args.var)
        opts = {'Numeric' 'String'};
        sel = listdlg(...
            'PromptString', sprintf('What type of variable is\n#%s?', args.var{idx}),...
            'ListString', opts,...
            'SelectionMode', 'single');
        if isempty(sel)
            return
        else
            args.type = [args.type opts(sel)];
        end
    end
end

fprintf('Adding the following event variables:\n');
fprintf('\t#%s\n', args.var{:});

outargs = args;

end

function EYE = sub_evar_read(EYE, varargin)

args = parseargs(varargin{:});

n_val = 0;
read_from = find(pupl_event_sel(EYE.event, args.sel));
for eventidx = read_from
    switch args.method
        case 're'
            tokens = regexp(EYE.event(eventidx).name, args.expr, 'tokens');
            tokens = tokens{:};
            for varidx = 1:numel(tokens)
                var = tokens{varidx};
                if strcmp(args.type{varidx}, 'Numeric')
                    var = str2num(tokens{varidx});
                end
                if ~isempty(var)
                    n_val = n_val + 1;
                end
                EYE.event(eventidx).(args.var{varidx}) = var;
            end
        case 'evar'
            var = pupl_evar_eval(args.expr, EYE.event(eventidx));
            if isnumeric(var)
                if strcmp(args.type{1}, 'String')
                    var = num2str(var);
                end
            elseif isstr(var)
                if strcmp(args.type{1}, 'Numeric')
                    var = str2num(var);
                end
            end
            if ~isempty(var)
                n_val = n_val + 1;
            end
            EYE.event(eventidx).(args.var{1}) = var;
    end
end

fprintf('%d non-empty event variables read from %d events\n', n_val, numel(read_from));

end