
function EYE = attachevents(EYE, varargin)

% Finds an offset between the EYE event timeline and an event log timeline,
% the uses it to attach events from the event log to EYE.event
%   Inputs
% eventLogs--struct array
% eyeEventsToAlign--
% eventLogEventsToAlign--
% eventsToAttach--
% namesToAttach--
% overWrite--true or false; overwrite events already in EYE?
%   Output
% EYE--struct array

p = inputParser;
addParameter(p, 'eventlogs', []);
addParameter(p, 'eyeeventstoalign', []);
addParameter(p, 'eventlogeventstoalign', []);
addParameter(p, 'eventstoattach', []);
addParameter(p, 'namestoattach', []);
addParameter(p, 'overwrite', []);
parse(p, varargin{:})

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);
if isempty(p.Results.eventlogs)
    eventLogs = pupl_load('type', 'event logs');
else
    eventLogs = p.Results.eventlogs;
end
callStr = sprintf('%s''eventLogs'', %s, ', callStr, all2str(eventLogs));

if isempty(p.Results.eventlogeventstoalign) || isempty(p.Results.eyeeventstoalign)
    [eyeEventsToAlign, eventLogEventsToAlign] = UI_geteventcorrespondence(EYE, eventLogs);
    if isempty(eyeEventsToAlign)
        return
    end
else
    eyeEventsToAlign = p.Results.eyeeventstoalign;
    eventLogEventsToAlign = p.Results.eventlogeventstoalign;
end
callStr = sprintf('%s''eventlogeventstoalign'', %s, ''eyeeventstoalign'', %s, ', callStr, all2str(eventLogEventsToAlign), all2str(eyeEventsToAlign));

if isempty(p.Results.eventstoattach) || isempty(p.Results.namestoattach)
    [eventsToAttach, namesToAttach] = UI_geteventstoattach(eventLogs);
    if isempty(eventsToAttach)
        return
    end
else
    eventsToAttach = p.Results.eventstoattach;
    namesToAttach = p.Results.namestoattach;
end 
callStr = sprintf('%s''eventstoattach'', %s, ''namestoattach'', %s, ', callStr, eventsToAttach, namesToAttach);

if p.Results.namestoattach == 0
    namesToAttach = eventsToAttach;
end

if isempty(p.Results.overwrite)
    q = 'Overwrite events already in eye data?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
    switch a
        case 'Yes'
            overwrite = true;
        case 'No'
            overwrite = false;
        otherwise
            return
    end
else
    overwrite = p.Results.overwrite;
end
callStr = sprintf('%s''overwrite'', %s)', callStr, all2str(overwrite));
% Find offset and attach events

for dataIdx = 1:numel(EYE)
    offsetParams = findtimelineoffset(EYE(dataIdx),...
        eventLogs(dataIdx),...
        eyeEventsToAlign,...
        eventLogEventsToAlign);
    if isempty(offsetParams)
        EYE = [];
        return
    end
    EYE(dataIdx) = copyevents(EYE(dataIdx),...
        eventLogs(dataIdx),...
        offsetParams,...
        eventsToAttach,...
        namesToAttach,...
        overwrite);
end

end