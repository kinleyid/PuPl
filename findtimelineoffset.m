function bestOffsetParams = findtimelineoffset(EYE, eventLog, eyeEventSets, eventLogEventSets, varargin)

%   Inputs
% EYE--single struct
% eventLog--single struct

% Takes 2 structs with struct arrays "event" with fields "type" (string)
% and "time" (in ms), returns Params, the lowest square error solution to
% [Struct1.event.time] = Params(1)*[Struct2.event.time] + Params(2)
% for the correspondence dictated by Struct1EventTypes and
% Struct2EventTypes, where both are themselves struct arrays with field
% "BinMembers" (cell array of strings).

if numel(varargin) < 1
    tolerance = 50;
else
    tolerance = varargin{1};
end

if numel(varargin) < 2
    pct = 0.5;
else
    pct = varargin{2};
end

allPossibleOffsets = reshape(mergefields(EYE, 'event', 'time') - mergefields(eventLog, 'event', 'time'), 1, []);

while true
    lowestErr = inf;
    bestParams = [];
    for candidateOffset = allPossibleOffsets
        eyeTimes = [];
        eventLogTimes = [];
        for i = 1:numel(eyeEventSets)
            currEyeTimes = mergefields(EYE.event(ismember({EYE.event.name}, eyeEventSets)), 'time');
            currEventLogTimes = mergefields(eventLog.event(ismember({eventLog.event.name}, eventLogEventSets)), 'time');
            matches = abs(currEyeTimes(:) - currEventLogTimes(:)' - candidateOffset) < tolerance;
            if nnz(matches) < pct*min(size(matches))
                continue
            else
                eyeTimes = cat(1, eyeTimes, reshape(currEyeTimes(any(matches, 2)), [], 1));
                eventLogTimes = cat(1, eventLogTimes, reshape(currEventLogTimes(any(matches, 1)), [], 1));
            end
        end
        currOffsetParams = [eventLogTimes ones(size(eventLogTimes))] \ eyeTimes;
        currErr = sum((eyeTimes - [eventLogTimes ones(size(eventLogTimes))]*currOffsetParams).^2);
        if currErr < lowestErr
            lowestErr = currErr;
            bestOffsetParams = currOffsetParams;
        end
    end
    
    if isempty(bestParams)
        q = 'No offset could be found';
        a = questdlg(q, q, 'Quit', 'Try different events', 'Try different events');
        if strcmp(a, 'Quit')
            return
        elseif strcmp(a, 'Try difference events')
            [eyeEventSets, eventLogEventSets] = UI_geteventcorrespondence(EYE, eventLog);
        end
    else
        return
    end
end

end