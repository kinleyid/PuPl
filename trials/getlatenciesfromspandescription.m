function latencies = getlatenciesfromspandescription(EYE, spanDescription)

%  Inputs
% EYE--SINGLE struct, not array
% spanDescription--SINGLE struct, not array

%  Outputs
% latencies--cell array of integer arrays

lims = {}; % Get span-delimiting latencies
for limIdx = 1:2
    
    eventIdx = find(strcmp({EYE.event.type}, spanDescription.lims(limIdx).event));
    if spanDescription.lims(limIdx).instance ~= 0
        % A particular serial instance, not just any
        eventIdx = eventIdx(spanDescription.lims(limIdx).instance);
    end
    
    % Parse string
    
    currBookend = parsetimestr(spanDescription.lims(limIdx).bookend, EYE.srate);
    
    lims{limIdx} = round(...
        [EYE.event(eventIdx).time]*EYE.srate + 1 ... % latencies of events
        + repmat(round(currBookend*EYE.srate), 1, numel(eventIdx))); % plus bookends
end

if numel(lims{1}) ~= numel(lims{2})
    error('Pupillometry error: limit number problem');
end

latencies = cell(1, numel(lims{1}));

for spanIdx = 1:numel(lims{1})
    latencies{spanIdx} = lims{1}(spanIdx):lims{2}(spanIdx);
end

end
