function EYE = extractepochs(EYE, events, lims)

for dataidx = 1:numel(EYE)
    currEvents = {EYE(dataidx).event.type};
    currLims = [parsetimestr(lims{1}, EYE(dataidx).srate) parsetimestr(lims{2}, EYE(dataidx).srate)];
    relLatencies = currLims(1):currLims(2);
    for eventType = reshape(events, 1, [])
        for eventidx = find(strcmp(currEvents, eventType))
            currEpoch = struct(...
                'reject', false,...
                'relLatencies', relLatencies,...
                'event', EYE(dataidx).event(eventidx).type);
            currEpoch.absLatencies = EYE(dataidx).event(eventidx).latency + relLatencies;
            for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
                currEpoch.diam.(stream{:}) = EYE(dataidx).diam.(stream{:})(currEpoch.absLatencies);
            end
            EYE(dataidx).epoch = cat(1, EYE(dataidx).epoch, currEpoch);
        end
    end
end

end