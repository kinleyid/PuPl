
function b = mergelr(s)

alldata = {};
for field = {'left' 'right'}
    if isfield(s.pupil, field{:})        
        alldata{end + 1} = s.pupil.(field{:});
    end
end
alldata = cat(1, alldata{:});

b = nanmean_bc(alldata, 1);

end