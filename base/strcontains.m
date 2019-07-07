
function idx = strcontains(str, maycontain)

idx = ~cellfun(@isempty, strfind(cellstr(str), maycontain));

end