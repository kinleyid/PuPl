
function epochidx = getepochidx(EYE, setdescription)

% Gets the epochs corresponding to a trial set description

epochidx = find(ismember({EYE.epoch.name}, setdescription.members));

end