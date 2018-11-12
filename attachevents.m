function EYE = attachevents(EYE, varargin)

% EYE may be an array of eye structs

% Input args: eventlogs, alignmentstruct, eventstoattach, namestoattach

p = inputParser;
addParameter(p, 'eventlogs', []);
addParameter(p, 'eyeeventstoalign', []);
addParameter(p, 'eventlogeventstoalign', []);
addParameter(p, 'eventstoattach', []);
addParameter(p, 'namestoattach', []);
addParameter(p, 'saveto', []);
parse(p, varargin{:})

% use UI to get missing args

if isempty(p.Results.eventlogs)
    uiwait(msgbox('Select event logs'))
    [eventLogFiles, eventLogDirectory] = uigetfile('./*.*',...
        'Select event logs',...
        'MultiSelect','on');
    eventLogFiles = cellstr(eventLogFiles);
    eventLogs = [];
    for fileIdx = 1:numel(eventLogFiles)
        eventLogs(fileIdx) = load(...
            [eventLogDirectory '\\' eventLogFiles{fileIdx}], '-mat');
    end
else
    eventLogs = p.Results.eventlogs;
end

if isempty(p.Results.eventlogeventstoalign) || isempty(p.Results.eyeeventstoalign)
    [eyeEventsToAlign, eventLogEventsToAlign] = UI_geteventcorrespondence(EYE(1), eventLogs(1), false);
else
    eyeEventsToAlign = p.Results.eyeeventstoalign;
    eventLogEventsToAlign = p.Results.eventlogeventstoalign;
end

if isempty(p.Results.eventstoattach) || isempty(p.Results.namestoattach)
    [eventsToAttach,namesToAttach] = UI_geteventstoattach(eventLogs(1));
else
    eventsToAttach = p.Results.eventstoattach;
    namesToAttach = p.Results.namestoattach;
end 
if p.Results.namestoattach == 0
    namesToAttach = eventsToAttach;
end

% Find offset and attach events

for dataIdx = 1:numel(EYE)
    offsetParams = findoffset(EYE(dataIdx),...
        eventLogs(dataIdx),...
        eyeEventsToAlign,...
        eventLogEventsToAlign);
    EYE(dataIdx) = copyevents(EYE(dataIdx),...
        eventLogs(dataIdx),...
        offsetParams,...
        eventsToAttach,...
        namesToAttach);
end

saveeyedata(EYE, p.Results.saveto, '', 'with events attached');