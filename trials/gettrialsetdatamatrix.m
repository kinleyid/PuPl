
function [data, isrej] = gettrialsetdatamatrix(EYE, setname)

data = cell(numel(EYE), 1);
isrej = cell(1, numel(EYE));
for dataidx = 1:numel(EYE)
    setidx = strcmp({EYE(dataidx).trialset.name}, setname);
    epochidx = getepochidx(EYE(dataidx), EYE(dataidx).trialset(setidx).description);
    vecdata = gettrialdata(EYE(dataidx), epochidx, 'diam', 'both');
    vecdata = [vecdata{:}];
    currisrej = [EYE(dataidx).epoch(epochidx).reject];
    matdata = reshape(vecdata, numel(unfold(EYE(dataidx).trialset(setidx).rellims)), [])';
    data{dataidx} = matdata;
    isrej{dataidx} = currisrej;
end

data = cell2mat(data);
isrej = cell2mat(isrej)';

end