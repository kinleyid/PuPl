
function [mat, isrej] = gettrialsetdatamatrix(EYE, setname)

mat = [];
isrej = [];
for dataidx = 1:numel(EYE)
    setidx = strcmp({EYE(dataidx).trialset.name}, setname);
    vecData = mergefields(EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx), 'diam', 'both');
    currIsRej = [EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx).reject];
    matData = reshape(vecData, numel(EYE(dataidx).trialset(setidx).relLatencies), [])';
    mat = [
        mat
        matData
    ];
    isrej = [
        isrej
        currIsRej(:)
    ];
end

end