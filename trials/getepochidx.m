
function epochidx = getepochidx(EYE, setdescription)

% Gets the epochs corresponding to a trial set description

epochidx = find(pupl_event_select([EYE.epoch.event], setdescription.members));

end