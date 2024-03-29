
function out = pupl_feval(urfunc, EYE, varargin)

% Runs a processing function and records it in the processing history

if iscell(urfunc)
    macro = true; % Function takes entire array, not just a single struct
    func = urfunc{:};
else
    macro = false;
    func = urfunc;
end

if ischar(func)
    func = str2func(func);
end

% Get arguments
getargs = func(); % nargin = 0
if isa(getargs, 'function_handle')
    if nargout(getargs) < 1
        args = struct([]);
    else
        switch nargin(getargs)
            case -1
                args = getargs(varargin{:});
            case -2
                args = getargs(EYE, varargin{:});
            otherwise
                error
        end
    end
else
    args = struct([]);
end
if isstruct(args)
    args = pupl_struct2args(args);    
elseif isempty(args)
    out = 0; % User exited
    return
end

% Generate caller string for history field
args_str = cellfun(@all2str, args, 'UniformOutput', false);
if isempty(args_str)
    args_str = '';
else
    args_str = sprintf(', %s', args_str{:});
end
global pupl_globals;
callstr = sprintf('%s = %s(%s, %s%s);',....
    pupl_globals.datavarname, mfilename, all2str(urfunc), pupl_globals.datavarname, args_str);

% Apply the function
if ~pupl_globals.isoctave
    % Matlab can display a clickable hyperlink to the source file
    fprintf('Running <a href="matlab:edit %s">%s</a>...\n', func2str(func), func2str(func));
else
    % Octave cannot
    fprintf('Running %s...\n', func2str(func));
end

for dataidx = 1:numel(EYE)
    EYE(dataidx).history{end + 1} = callstr;
    if ~macro
        fprintf('----Processing recording "%s"...\n', EYE(dataidx).name);
        tmp = func(EYE(dataidx), args{:});
        [tmp, EYE] = fieldconsistency(tmp, EYE);
        EYE(dataidx) = tmp;
        fprintf('----Done processing %s\n', EYE(dataidx).name);
    end
end

if macro
    EYE = func(EYE, args{:});
end

EYE = pupl_check(EYE);
out = EYE;

end
