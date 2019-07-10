
function info = parseBIDSfilename(filehead)

info = [];
fields = stringsplit(filehead, '_');
for field = fields(1:end-1)
    currfield = field{:};
    info.(currfield(1:find(currfield == '-', 1) - 1)) =...
        currfield(find(currfield == '-', 1) + 1:end);
end

end