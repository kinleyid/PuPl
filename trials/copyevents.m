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
    times = [
        reshape([eventLog.event(matchIdx).time], [], 1)...
        ones(nnz(matchIdx), 1)]*offsetParams;
    EYE.event = [reshape(EYE.event, 1, [])...
        reshape(struct(...
            'type', namesToAttach(typeIdx),...
            'time', num2cell(times),...
            'rt', num2cell([eventLog.event.rt]),...
            'latency', num2cell(round(times*EYE.srate + 1))),...
        1, [])
    ];
end

fprintf('%d events written\n', numel(EYE.event) - initEventCount);

[~, I] = sort([EYE.event.time]);
EYE.event = EYE.event(I);

end