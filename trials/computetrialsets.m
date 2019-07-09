
function EYE = computetrialsets(EYE)

% EYE is a single struct, not array

for setidx = 1:numel(EYE.bin)
    currset = [];
    for epochidx = 1:numel(EYE.epoch)
        if ~EYE.epoch(epochidx).reject
            if ismember(EYE.epoch(epochidx).name, {EYE.bin(setidx).epochs})
                currset(end+1) = EYE.epoch(epochidx);
            end
        end
    end
    EYE.bin(setidx).contents = currset;
end

end