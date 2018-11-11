function EYE = copyevents(EYE,eventLog,offsetParams,eventsToAttach,namesToAttach)

eventTimes = [];
eventNames = [];
for i = 1:length(eventsToAttach)    
    Struct2Times = [eventLog.event(strcmp({eventLog.event.type},eventsToAttach(i))).time];
    CurrTimes = num2cell([Struct2Times(:) ones(size(Struct2Times(:)))]*offsetParams);
    eventTimes = [eventTimes; CurrTimes(:)];
    CurrNames = repmat(namesToAttach(i),size(Struct2Times));
    eventNames = [eventNames; CurrNames(:)];
end

TempEvent = [];
[TempEvent(1:length(eventTimes)).time] = eventTimes{:};
[TempEvent(1:length(eventNames)).type] = eventNames{:};
eventLatencies = num2cell(round(([EYE.event.time])*EYE.srate/1000) + 1);
[EYE.event(1:length(eventLatencies)).latency] = eventLatencies{:};
% Standardize orientation of event structure
EYE.event = EYE.event(:);
EYE.event = cat(1,EYE.event,TempEvent(:));

% EYE.event = rmfield(EYE.event,'time'); Remove time field?
% Sort events by time of occurrence
[~,idx] = sort([EYE.event.time]);
EYE.event = EYE.event(idx);
