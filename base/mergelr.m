
function b = mergelr(s)

alldata = [];
for field = {'left' 'right'}
    if isfield(s.pupil, field{:})        
        alldata = [
            alldata
            s.pupil.(field{:})
        ];
    end
end

b = nanmean_bc(alldata, 1);

end