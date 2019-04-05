
function outStruct = pupl_check(outStruct)

% Ensures that the EYE struct array conforms to pupl's expectations

if isfield(outStruct, 'event')
    for dataidx = 1:numel(outStruct)
        newEvents = cellfun(@num2str, {outStruct(dataidx).event.type}, 'un', 0);
        [outStruct(dataidx).event.type] = newEvents{:};
    end
end

if ~isfield(outStruct, 'history')
    for dataidx = 1:numel(outStruct)
        outStruct(dataidx).history = {};
    end
end

end