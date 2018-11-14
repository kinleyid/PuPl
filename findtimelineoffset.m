function bestOffsetParams = findtimelineoffset(EYE, eventLog, eyeEventSets, eventLogEventSets, varargin)

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
        for cIdx = 1:numel(eyeEventSets) % correspondence idx
            currEyeTimes = mergefields(EYE.event(ismember({EYE.event.name}, eyeEventSets{cIdx})), 'time');
            currEventLogTimes = mergefields(eventLog.event(ismember({eventLog.event.name}, eventLogEventSets{cIdx})), 'time');
            matches = abs(currEyeTimes(:) - currEventLogTimes - candidateOffset) < tolerance;
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