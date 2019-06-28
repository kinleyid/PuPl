
function callstr = getcallstr(p)

allfuncs = dbstack;
callstr = sprintf('eyeData = %s(eyeData, ', allfuncs(2).name);
for variable = reshape(fieldnames(p.Results), 1, [])
    callstr = sprintf('%s''%s'', %s, ', callstr, variable{:}, all2str(evalin('caller', variable{:})));
end
callstr(end-1:end) = [];
callstr(end+1) = ')';

end