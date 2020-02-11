
function out = pupl_alignbysync(EYE, varargin)

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

if nargin == 0
    out = @getargs;
else
    out = sub_alignbysync(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'eyeeventstoalign' []
    'eventlogeventstoalign' []
    'eventstoattach' []
    'namestoattach' []
    'overwrite' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.eyeeventstoalign) || isempty(args.eventlogeventstoalign)
    [args.eyeeventstoalign, args.eventlogeventstoalign] = UI_geteventcorrespondence(EYE, [EYE.eventlog]);
    if isempty(args.eyeeventstoalign)
        return
    end
end

if isempty(args.eventstoattach)
    eventOptions = unique(mergefields(EYE, 'eventlog', 'event', 'type'));
    sel = listdlgregexp(...
        'PromptString', 'Which events from the event log should be attached to the eye data?',...
        'ListString', eventOptions);
    if isempty(sel)
        return
    end
    args.eventstoattach = eventOptions(sel);
end

if isempty(args.namestoattach)
    q = 'Attach the events under different names?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
    switch a
        case 'Yes'
            args.namestoattach = UI_getnames(args.eventstoattach);
        case 'No'
            args.namestoattach = args.eventstoattach;
        otherwise
            return
    end
end

if isempty(args.overwrite)
    q = 'Overwrite events already in eye data?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
    switch a
        case 'Yes'
            args.overwrite = true;
        case 'No'
            args.overwrite = false;
        otherwise
            return
    end
end

outargs = args;

end

function EYE = sub_alignbysync(EYE, varargin)

args = parseargs(varargin{:});

% Find offset and attach events
offsetParams = findtimelineoffset(EYE,...
    EYE.eventlog,...
    args.eyeeventstoalign,...
    args.eventlogeventstoalign);
if isempty(offsetParams)
    EYE = [];
    return
end
EYE = copyevents(EYE,...
    EYE.eventlog,...
    offsetParams,...
    args.eventstoattach,...
    args.namestoattach,...
    args.overwrite);

end

function bestParams = findtimelineoffset(EYE, eventLog, eyeEventSets, eventLogEventSets, varargin)

% Find an offset between the events in EYE and the events in eventLog
%   Inputs
% EYE--single struct
% eventLog--single struct
% eyeEventSets--cell array of char cell arrays
% eventLogEventSets--cell array of char cell arrays
% varargin{1}--tolerance
% varargin{2}--min percent matches
%   Outputs
% bestOffsetParams--the lowest square error solution to:
%   [EYE.event.time] = Params(1)*[eventLog.event.time] + Params(2)
%
%   NB
% Timestamps are asusmed to be in seconds

fprintf('Searching for an offset between %s and %s...\n', EYE.name, eventLog.name)

if numel(varargin) < 1
    tolerance = 0.05; % 50 ms
else
    tolerance = varargin{1};
end

if numel(varargin) < 2
    pct = 0.80;
else
    pct = varargin{2};
end

allPossibleOffsets = [];
correspondences = struct('eyeTimes', [], 'eventLogTimes', []); % Pre-generate times for speed
for cIdx = 1:numel(eyeEventSets) % correspondence idx
    eyeTimes = reshape(...
        mergefields(EYE.event(ismember({EYE.event.type}, eyeEventSets{cIdx})), 'time'),...
        [], 1);
    eventLogTimes = reshape(...
        mergefields(eventLog.event(ismember({eventLog.event.type}, eventLogEventSets{cIdx})), 'time'),...
        1, []);
    correspondences(cIdx).eyeTimes = eyeTimes;
    correspondences(cIdx).eventLogTimes = eventLogTimes;
    allPossibleOffsets = cat(2, allPossibleOffsets,...
        reshape(bsxfun(@minus, eyeTimes, eventLogTimes), 1, []));
end

while true
    lowestErr = inf;
    bestParams = [];
    fprintf('\tTesting %d possible offsets...\n', numel(allPossibleOffsets));
    fprintf('\tProportion complete: %0.2f', 0);
    for offsetIdx = 1:numel(allPossibleOffsets)
        fprintf('\b\b\b\b%0.2f', offsetIdx/numel(allPossibleOffsets));
        candidateOffset = allPossibleOffsets(offsetIdx);
        eyeTimes = [];
        eventLogTimes = [];
        flag = false;
        for cIdx = 1:numel(eyeEventSets)
            matches = abs(bsxfun(@minus, correspondences(cIdx).eyeTimes, correspondences(cIdx).eventLogTimes) - candidateOffset) < tolerance;
            if nnz(matches) < pct*min(size(matches))
                flag = true;
                break
            else
                eyeTimes = cat(1, eyeTimes, correspondences(cIdx).eyeTimes(any(matches, 2)));
                eventLogTimes = cat(1, eventLogTimes, reshape(correspondences(cIdx).eventLogTimes(any(matches, 1)), [], 1));
            end
        end
        if flag
            continue
        end
        currOffsetParams = [eventLogTimes ones(size(eventLogTimes))] \ eyeTimes;
        currErr = mean((eyeTimes - [eventLogTimes ones(size(eventLogTimes))]*currOffsetParams).^2);
        if currErr < lowestErr
            lowestErr = currErr;
            bestParams = currOffsetParams;
        end
    end
    fprintf('\b\b\b\bdone\n')
    if isempty(bestParams)
        q = 'No offset could be found';
        a = questdlg(q, q, 'Quit', 'Try different events', 'Try different events');
        switch a
            case 'Try different events'
                [eyeEventSets, eventLogEventSets] = UI_geteventcorrespondence(EYE, eventLog);
            otherwise
                return
        end
    else
        fprintf('\tOffset estimate: %.3f minutes.\n', bestParams(2)/60);
        fprintf('\tEvents aligned with MS error %.10f ms^2\n', lowestErr);
        return
    end
end

end

function EYE = copyevents(EYE, eventLog, offsetParams, eventsToAttach, namesToAttach, overwrite)

% Copies events from eventLog to EYE
%   Inputs
% EYE--single struct
% eventLog--single struct
% offsetParams--numeric array with 2 elements
% eventsToAttach--
% namesToAttach--cell array of chars

if overwrite
    fprintf('\tDeleting %d pre-existing event data from %s...\n', numel(EYE.event), EYE.name)
    EYE.event = [];
end

initEventCount = numel(EYE.event);

fprintf('\tWriting events from %s to %s...', eventLog.name, EYE.name);

for typeIdx = 1:numel(eventsToAttach)
    matchIdx = strcmpi({eventLog.event.type}, eventsToAttach(typeIdx));
    if ~any(matchIdx)
        continue
    end
    times = [
        reshape([eventLog.event(matchIdx).time], [], 1)...
        ones(nnz(matchIdx), 1)]*offsetParams;
    EYE.event = [reshape(EYE.event, 1, [])...
        reshape(struct(...
            'type', namesToAttach(typeIdx),...
            'time', reshape(num2cell(times), 1, []),...
            'rt', num2cell([eventLog.event(matchIdx).rt]),...
            'latency', reshape(num2cell(round(times*EYE.srate + 1)), 1, [])),...
        1, [])
    ];
end

fprintf('%d events written\n', numel(EYE.event) - initEventCount);

[~, I] = sort([EYE.event.time]);
EYE.event = EYE.event(I);

end

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
    'Style', 'pushbutton',...
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

if strcmp(e.Key, 'return')
    uiresume(gcbf)
end

end