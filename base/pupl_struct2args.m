
function outargs = pupl_struct2args(inargs)

fields = fieldnames(inargs);
outargs = {};
for field = fields(:)'
    outargs(end + 1) = field;
    outargs{end + 1} = inargs.(field{:});
end

end