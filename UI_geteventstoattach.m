function [EventLogEventTypesToAttach,NamesToUse] = UI_geteventstoattach(EventLog)

EventLogEventTypes = unique({EventLog.event.type});

Idx = listdlg('PromptString','Which events from the event log should be attached to the eye data?',...
    'SelectionMode','multiple',...
    'ListSize',[500,300],...
    'ListString',EventLogEventTypes);
EventLogEventTypesToAttach = EventLogEventTypes(Idx);
NamesToUse = {};
%{
for i = 1:10:length(EventLogEventTypesToAttach)
    CurrNamesToUse = inputdlg(EventLogEventTypesToAttach(i:min(length(EventLogEventTypesToAttach),i+9)),...
        'Which names should be used for the events?',...
        [1 100],EventLogEventTypesToAttach(i:min(length(EventLogEventTypesToAttach),i+9)));
    NamesToUse = cat(1,NamesToUse,CurrNamesToUse);
end
%}
NamesToUse = UI_getnames(EventLogEventTypesToAttach);

end