
function mat = gettrialsetdatamatrix(EYE, setname)

mat = [];
for dataidx = 1:numel(EYE)
    setidx = strcmp({EYE(dataidx).trialset.name}, setname);
    vecData = mergefields(EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx), 'diam', 'both');
    matData = reshape(vecData, numel(EYE(dataidx).trialset(setidx).relLatencies), [])';
    mat = [
        mat
        matData
    ];
end

end