function [eventsToAttach, namesToUse] = UI_geteventstoattach(eventLogs)

eventTypes = unique(mergefields(eventLogs, 'event', 'type'));

Idx = listdlg('PromptString', 'Which events from the event log should be attached to the eye data?',...
    'SelectionMode', 'multiple',...
    'ListSize', [500,300],...
    'ListString', eventTypes);
eventsToAttach = eventTypes(Idx);

namesToUse = UI_getnames(eventsToAttach);

end