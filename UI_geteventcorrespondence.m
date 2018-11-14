function [eyeEventSets, eventLogEventSets] = UI_geteventcorrespondence(EYE, eventLogs)

%   Inputs
% EYE--struct array
% eventLogs--struct array
%   Outputs
% eyeEventSets--cell array of char cell arrays
% eventLogEventSets--cell array of char cell arrays

eyeEvents = unique(mergefields(EYE, 'event', 'type'));
eventLogEvents = unique(mergefields(eventLogs, 'event', 'type'));

[eyeEventSets, eventLogEventSets] = deal({});

uiwait(msgbox('Create corresponding sets of events in the eye data and event logs'))

while true
    eyeEventSets{numel(eyeEventSets) + 1} = ...
        eyeEvents(listdlg('PromptString', 'Select eye events',...
            'ListString', eyeEvents));
    eventLogEventSets{numel(eventLogEventSets) + 1} = ...
        eventLogEvents(listdlg('PromptString', 'What are the correcponding event log events?',...
            'ListString', eventLogEvents));
    q = 'Add another pair of corresponding event sets?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        return
    end
end

end