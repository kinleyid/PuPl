
function EYE = pupl_applytoarray(func, EYE, varargin)

% Get arguments
getargs = func();
args = getargs(EYE, varargin{:});
if isempty(args)
    return
elseif isstruct(args)
    args = pupl_struct2args(args);
end

% Generate caller string for history field
args_str = cellfun(@all2str, args, 'UniformOutput', false);
args_str = sprintf('%s, ', args_str{:});
args_str = args_str(1:end-2); % Remove trailing comma and space
global pupl_globals;
callstr = sprintf('%s = %s(@%s, %s, %s);',....
    pupl_globals.datavarname, mfilename, func2str(func), pupl_globals.datavarname, args_str);

% Apply the function
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    EYE(dataidx) = func(EYE, args{:});
    EYE(dataidx).history{end + 1} = callstr;
    fprintf('\tdone\n');
end
fprintf('done\n');
EYE = pupl_check(EYE);

end
