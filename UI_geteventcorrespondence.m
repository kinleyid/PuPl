function [eyeEventSets, eventLogEventSets] = UI_geteventcorrespondence(EYE, eventLogs)

%   Inputs
% EYE--struct array
% eventLogs--struct array
%   Outputs
%

eyeEvents = unique(mergefields(EYE, 'event', 'type'));
eventLogEvents = unique(mergefields(eventLogs, 'event', 'type'));

eyeEventSets = {};
eventLogEventSets = {};

while true
    eyeEventSets{numel(eyeEventSets) + 1} = ...
        eyeEvents(listdlg('PromptString', 'Select eye events',...
            'ListString', eyeEvents,...
            'MultiSelect', 'on'));
    eventLogEventSets{numel(eventLogEventSets) + 1} = ...
        eventLogEvents(listdlg('PromptString', 'What are the correcponding event log events?',...
            'ListString', eventLogEvents,...
            'MultiSelect', 'on'));
    q = 'Add another pair of corresponding event sets?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        return
    end
end

end