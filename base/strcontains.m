
function idx = strcontains(str, maycontain)

idx = ~cellfun(@isempty, strfind(str, maycontain));

end