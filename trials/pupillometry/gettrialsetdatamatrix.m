
function matData = gettrialsetdatamatrix(EYE, setidx)

vecData = mergefields(EYE.epoch(EYE.trialset(setidx).epochidx), 'diam', 'both');
matData = reshape(vecData, numel(EYE.trialset(setidx).relLatencies), [])';

end