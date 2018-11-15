function EYE = attachevents(EYE, varargin)

%   Inputs
% eventLogs--struct array
% eyeEventsToAlign--
% eventLogEventsToAlign--
% eventsToAttach--
% namesToAttach--
%   Output
% EYE--struct array

% EYE may be an array of eye structs

% Input args: eventlogs, alignmentstruct, eventstoattach, namestoattach

p = inputParser;
addParameter(p, 'eventlogs', []);
addParameter(p, 'eyeeventstoalign', []);
addParameter(p, 'eventlogeventstoalign', []);
addParameter(p, 'eventstoattach', []);
addParameter(p, 'namestoattach', []);
addParameter(p, 'UI', []);
parse(p, varargin{:})

if isempty(p.Results.eventlogs)
    eventLogs = pupl_load('type', 'event logs');
else
    eventLogs = p.Results.eventlogs;
end

if isempty(p.Results.eventlogeventstoalign) || isempty(p.Results.eyeeventstoalign)
    [eyeEventsToAlign, eventLogEventsToAlign] = UI_geteventcorrespondence(EYE, eventLogs);
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
        namesToAttach);
end

if ~isempty(p.Results.UI)
    p.Results.UI.UserData.EYE = EYE;
    p.Results.UI.Visible = 'off';
    p.Results.UI.Visible = 'on';
end

end