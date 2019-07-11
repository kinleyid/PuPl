
function EYE = sub_createtrialsets(EYE, setdescriptions, overwrite)

if overwrite
    EYE.trialset = [];
end

for setidx = 1:numel(setdescriptions)
    epochidx = find(ismember({EYE.epoch.name}, setdescriptions(setidx).members));
    rellims = {EYE.epoch(epochidx).rellims};
    if numel(unique(cellfun(@num2str, rellims, 'UniformOutput', 0))) > 1
        warning('You are combining epochs into a bin that do not all begin and end at the same time relative to their events');
        rellims = [];
    else
        rellims = EYE.epoch(1).rellims;
    end
    EYE.trialset = [EYE.trialset struct(...
        'name', setdescriptions(setidx).name,...
        'members', {setdescriptions(setidx).members},...
        'rellims', rellims,...
        'epochidx', epochidx)];
end

end