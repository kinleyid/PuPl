function [eyeEventSets, eventLogEventSets] = UI_geteventcorrespondence(EYE, eventLogs)

%   Inputs
% EYE--struct array
% eventLogs--struct array
%   Outputs
% eyeEventSets--cell array of char cell arrays
% eventLogEventSets--cell array of char cell arrays

eyeEvents = unique(mergefields(EYE, 'event', 'type'));
eventLogEvents = unique(mergefields(eventLogs, 'event', 'type'));

uiwait(msgbox('The eye data and event logs have to be aligned. Select which events in the eye data should be aligned with which events in the event logs'))

f = figure(...
    'Name', 'Event correspondence',...
    'NumberTitle', 'off',...
    'MenuBar', 'none');
eyePanel = uipanel(f,...
    'Title', 'Eye data events',...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.48 0.88]);
listboxregexp(eyePanel, eyeEvents)

eventLogsPanel = uipanel(f,...
    'Title', 'Event log events',...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.51 0.11 0.48 0.88]);
listboxregexp(eventLogsPanel, eventLogEvents)

uicontrol(f,...
    'String', 'Done',...
    'Units', 'normalized',...
    'Position', [0.26 0.01 0.48 0.08],...
    'KeyPressFcn', @returnresume,...
    'Callback', @(h,e)uiresume(f));

uiwait(f);
if isvalid(f)
    lb = findobj(eyePanel, 'Style', 'listbox');
    eyeEventSets = {eyeEvents(lb.Value)};
    lb = findobj(eventLogsPanel, 'Style', 'listbox');
    eventLogEventSets = {eventLogEvents(lb.Value)};
    close(f);
else
    [eyeEventSets, eventLogEventSets] = deal([]);
end

end

function returnresume(h,e)

if strcmp(e.Key, 'resume')
    uiresume(gcbf)
end

end