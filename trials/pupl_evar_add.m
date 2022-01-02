
function out = pupl_evar_add(EYE, varargin)
% Add event variables to events
%
% Inputs:
%   method: string
%       're': read from event name using regular expression capture
%       'evar': compute based on pre-existing event variables
%   sel: struct (see pupl_event_select)
%       selects the events to add event variable(s) to
%   expr: string
%       regular expression or Matlab expression to evaluate, depending on
%       the method being used to add event variables
%   var: cellstr
%       the name(s) of the resulting event variable(s)
%   type: cellstr
%       'numeric' or 'string', corresponding to the types of each event
%       variable
% Example:
%   pupl_evar_add(eye_data,...
%       'method', 're',...
%       'sel', {1 'Response'},...
%       'expr', 'FA=(\d+)',...
%       'var', {'FA'},...
%       'type', {'numeric'});
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
        sel = listdlgregexp(...
            'PromptString', sprintf('How do you want to define a new event variable?'),...
            'ListString', opts,...
            'SelectionMode', 'single',...
            'regexp', false);
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
    args.sel = pupl_UI_event_select(EYE, 'prompt', 'Add event variables to which events?');
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
        opts = {'numeric' 'string'};
        sel = listdlgregexp(...
            'PromptString', sprintf('What type of variable is #%s?', args.var{idx}),...
            'ListString', opts,...
            'SelectionMode', 'single',...
            'regexp', false);
        if isempty(sel)
            return
        else
            args.type = [args.type opts(sel)];
        end
    end
end

fprintf('Adding the following event variables:\n');
for ii = 1:numel(args.var)
    fprintf('\t#%s (%s)\n', args.var{ii}, args.type{ii});
end

outargs = args;

end

function EYE = sub_evar_read(EYE, varargin)

args = parseargs(varargin{:});

n_val = 0;
read_from = find(pupl_event_select(EYE.event, args.sel));
for eventidx = read_from
    switch args.method
        case 're'
            tokens = regexp(EYE.event(eventidx).name, args.expr, 'tokens');
            tokens = tokens{:};
            for varidx = 1:numel(tokens)
                var = tokens{varidx};
                if strcmpi(args.type{varidx}, 'numeric')
                    var = str2double(tokens{varidx});
                end
                if ~isempty(var)
                    n_val = n_val + 1;
                end
                EYE.event(eventidx).(args.var{varidx}) = var;
            end
        case 'evar'
            var = pupl_evar_eval(args.expr, EYE.event(eventidx));
            var = var{:};
            if ~ischar(var)
                if strcmpi(args.type{1}, 'string')
                    var = num2str(var);
                    if exist('string', 'file') % Convert to string scalar if supported
                        var = string(var);
                    end
                else
                    var = double(var);
                end
            else
                if strcmpi(args.type{1}, 'numeric')
                    var = str2num(var);
                end
            end
            if ~isempty(var)
                n_val = n_val + 1;
            end
            EYE.event(eventidx).(args.var{1}) = var;
    end
end

fprintf('%d non-empty event variables added to %d events\n', n_val, numel(read_from));

end