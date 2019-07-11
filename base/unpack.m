
function unpack(ipp)

for variable = ipp.Parameters
    evalin('caller', sprintf('%s = %s;', variable{:}, all2str(ipp.Results.(variable{:}))));
end

end