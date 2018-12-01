function [eventsToAttach, namesToUse] = UI_geteventstoattach(eventLogs)

eventTypes = unique(mergefields(eventLogs, 'event', 'type'));

Idx = listdlg('PromptString', 'Which events from the event log should be attached to the eye data?',...
    'SelectionMode', 'multiple',...
    'ListSize', [500,300],...
    'ListString', eventTypes);
eventsToAttach = eventTypes(Idx);

q = 'Attach the events under different names?';
a = questdlg(q, q, 'Yes', 'No', 'No');
switch a
    case 'Yes'
        namesToUse = UI_getnames(eventsToAttach);
    otherwise
        namesToUse = eventsToAttach;
end

end