
function EYE = attachevents(EYE, varargin)

% Finds an offset between the EYE event timeline and an event log timeline,
% the uses it to attach events from the event log to EYE.event
%   Inputs
% eyeEventsToAlign--
% eventLogEventsToAlign--
% eventsToAttach--
% namesToAttach--
% overWrite--true or false; overwrite events already in EYE?
%   Output
% EYE--struct array

p = inputParser;
addParameter(p, 'eyeeventstoalign', []);
addParameter(p, 'eventlogeventstoalign', []);
addParameter(p, 'eventstoattach', []);
addParameter(p, 'namestoattach', []);
addParameter(p, 'overwrite', []);
parse(p, varargin{:})

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);

if isempty(p.Results.eventlogeventstoalign) || isempty(p.Results.eyeeventstoalign)
    [eyeEventsToAlign, eventLogEventsToAlign] = UI_geteventcorrespondence(EYE, [EYE.eventlog]);
    if isempty(eyeEventsToAlign)
        return
    end
else
    eyeEventsToAlign = p.Results.eyeeventstoalign;
    eventLogEventsToAlign = p.Results.eventlogeventstoalign;
end
callStr = sprintf('%s''eventlogeventstoalign'', %s, ''eyeeventstoalign'', %s, ', callStr, all2str(eventLogEventsToAlign), all2str(eyeEventsToAlign));

if isempty(p.Results.eventstoattach) || isempty(p.Results.namestoattach)
    [eventsToAttach, namesToAttach] = UI_geteventstoattach([EYE.eventlog]);
    if isempty(eventsToAttach)
        return
    end
else
    eventsToAttach = p.Results.eventstoattach;
    namesToAttach = p.Results.namestoattach;
end 
callStr = sprintf('%s''eventstoattach'', %s, ''namestoattach'', %s, ', callStr, all2str(eventsToAttach), all2str(namesToAttach));

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

for dataidx = 1:numel(EYE)
    offsetParams = findtimelineoffset(EYE(dataidx),...
        EYE(dataidx).eventlog,...
        eyeEventsToAlign,...
        eventLogEventsToAlign);
    if isempty(offsetParams)
        EYE = [];
        return
    end
    EYE(dataidx) = copyevents(EYE(dataidx),...
        EYE(dataidx).eventlog,...
        offsetParams,...
        eventsToAttach,...
        namesToAttach,...
        overwrite);
    EYE(dataidx) = pupl_check(EYE(dataidx));
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
end
fprintf('Done\n');

end