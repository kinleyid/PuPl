
function EYE = pupl_applytoarray(func, EYE, varargin)

% Get arguments
args = func(); % nargin = 0
if isa(args, 'function_handle')
    if nargout(args) < 1
        args = struct([]);
    else
        args = args(EYE, varargin{:});
    end
end
if isstruct(args)
    args = pupl_struct2args(args);    
elseif isempty(args)
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
callstr = sprintf('%s = %s(@%s, %s%s);',....
    pupl_globals.datavarname, mfilename, func2str(func), pupl_globals.datavarname, args_str);

% Apply the function
if pupl_globals.isoctave
    fprintf('Running %s...\n', func2str(func));
else
    fprintf('Running <a href="matlab:edit %s">%s</a>...\n', func2str(func), func2str(func));
end
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    tmp = func(EYE(dataidx), args{:});
    [tmp, EYE] = fieldconsistency(tmp, EYE);
    tmp.history{end + 1} = callstr;
    EYE(dataidx) = tmp;
    fprintf('\t\tdone\n');
end
fprintf('Done\n');
EYE = pupl_check(EYE);

end
