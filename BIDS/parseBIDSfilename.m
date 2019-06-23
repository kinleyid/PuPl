
function info = parseBIDSfilename(filehead)

info = [];
fields = strsplit(filehead, '_');
for field = fields(1:end-1)
    currfield = field{:};
    info.(currfield(1:find(currfield == '-', 1) - 1)) =...
        currfield(find(currfield == '-', 1) + 1:end);
end

end