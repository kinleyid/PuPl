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
    pct = 0.5;
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
    fprintf('Testing %d possible offsets...\n', numel(allPossibleOffsets));
    fprintf('Proportion complete: %0.2f', 0);
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
        fprintf('Offset estimate: %.3f minutes.\n', bestParams(2)/60);
        fprintf('Events aligned with MS error %.10f ms^2\n', lowestErr);
        return
    end
end

end