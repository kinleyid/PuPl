
function [data, isrej] = gettrialsetdatamatrix(EYE, setname)

data = cell(numel(EYE), 1);
isrej = cell(1, numel(EYE));
for dataidx = 1:numel(EYE)
    setidx = strcmp({EYE(dataidx).trialset.name}, setname);
    vecdata = gettrialdata(EYE(dataidx), EYE(dataidx).trialset(setidx).epochidx, 'diam', 'both');
    vecdata = [vecdata{:}];
    % vecdata = mergefields(EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx), 'diam', 'both');
    currisrej = [EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx).reject];
    matdata = reshape(vecdata, numel(EYE(dataidx).trialset(setidx).relLatencies), [])';
    data{dataidx} = matdata;
    isrej{dataidx} = currisrej;
end

data = cell2mat(data);
isrej = cell2mat(isrej)';

end