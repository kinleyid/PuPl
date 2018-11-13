function EYE = copyevents(EYE, eventLog, offsetParams, eventsToAttach, namesToAttach)

[matchIdx, namesIdx] = ismember({eventLog.event.type}, eventsToAttach);
sz = [numel(matchIdx) 1];

EYE.event = cat(2, EYE.event(:)',...
    reshape(struct(...
        'time', {[reshape([eventLog.event(matchIdx).time], sz) ones(sz)]*offsetParams},...
        'type', namesToAttach(namesIdx)), sz));

[~, I] = sort([EYE.event.time]);
EYE.event = EYE.event(I);

end