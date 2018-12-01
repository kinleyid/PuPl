
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

if isempty(p.Results.eventlogs)
    eventLogs = pupl_load('type', 'event logs');
else
    eventLogs = p.Results.eventlogs;
end

if isempty(p.Results.eventlogeventstoalign) || isempty(p.Results.eyeeventstoalign)
    [eyeEventsToAlign, eventLogEventsToAlign] = UI_geteventcorrespondence(EYE, eventLogs);
    if isempty(eyeEventsToAlign)
        return
    end
else
    eyeEventsToAlign = p.Results.eyeeventstoalign;
    eventLogEventsToAlign = p.Results.eventlogeventstoalign;
end

if isempty(p.Results.eventstoattach) || isempty(p.Results.namestoattach)
    [eventsToAttach, namesToAttach] = UI_geteventstoattach(eventLogs);
else
    eventsToAttach = p.Results.eventstoattach;
    namesToAttach = p.Results.namestoattach;
end 

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

% Find offset and attach events

for dataIdx = 1:numel(EYE)
    offsetParams = findtimelineoffset(EYE(dataIdx),...
        eventLogs(dataIdx),...
        eyeEventsToAlign,...
        eventLogEventsToAlign);
    EYE(dataIdx) = copyevents(EYE(dataIdx),...
        eventLogs(dataIdx),...
        offsetParams,...
        eventsToAttach,...
        namesToAttach,...
        overwrite);
end

end