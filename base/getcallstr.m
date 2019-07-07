
function callstr = getcallstr(p, varargin)

if numel(varargin) > 0
    returnval = varargin{1};
else
    returnval = true;
end

allfuncs = dbstack;
if returnval
    callstr = 'eyeData = ';
else
    callstr = '';
end
callstr = sprintf('%s%s(eyeData, ', callstr, allfuncs(2).name);
for variable = reshape(fieldnames(p.Results), 1, [])
    callstr = sprintf('%s''%s'', %s, ', callstr, variable{:}, all2str(evalin('caller', variable{:})));
end
callstr(end-1:end) = [];
callstr(end+1) = ')';

end