
function b = mergelr(s)

alldata = [];
for field = {'left' 'right'}
    alldata = [
        alldata
        s.pupil.(field{:})
    ];
end

b = nanmean_bc(alldata, 1);

end