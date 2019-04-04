function [eventsToAttach, namesToUse] = UI_geteventstoattach(eventLogs)

eventTypes = unique(mergefields(eventLogs, 'event', 'type'));

Idx = listdlgregexp('PromptString', 'Which events from the event log should be attached to the eye data?',...
    'SelectionMode', 'multiple',...
    'ListSize', [500,300],...
    'ListString', eventTypes);
eventsToAttach = eventTypes(Idx);
if isempty(eventsToAttach)
    namesToUse = [];
    return
end

q = 'Attach the events under different names?';
a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
switch a
    case 'Yes'
        namesToUse = UI_getnames(eventsToAttach);
    case 'No'
        namesToUse = eventsToAttach;
    otherwise
        [eventsToAttach, namesToUse] = deal([]);
end

end