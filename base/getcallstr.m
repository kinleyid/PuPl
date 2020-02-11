
function callstr = getcallstr(varargin)

global pupl_globals;

if numel(varargin) > 0
    p = varargin{1};
else
    p = [];
end
if numel(varargin) > 1 
    returnval = varargin{2};
else
    returnval = true;
end

allfuncs = dbstack;
if returnval
    callstr = sprintf('%s = ', pupl_globals.datavarname);
else
    callstr = '';
end
callstr = sprintf('%s%s(%s, ', callstr, allfuncs(2).name, pupl_globals.datavarname);
if ~isempty(p)
    for variable = p.Parameters
        callstr = sprintf('%s''%s'', %s, ', callstr, variable{:}, all2str(evalin('caller', variable{:})));
    end
end
callstr(end-1:end) = [];
callstr(end+1) = ')';

end