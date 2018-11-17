function [structArray, structIn] = fieldconsistency(structArray, structIn)


if ~isempty(structArray)
    newFields = unique(([reshape(fieldnames(structArray), 1, []) reshape(fieldnames(structIn), 1, [])]));
    % Ensure structArray has all the fields structIn has
    for idx = 1:numel(structArray)
        for field = reshape(newFields(~ismember(newFields, fieldnames(structArray(idx)))), 1, [])
            structArray(idx).(field{:}) = [];
        end
    end
    % Vice versa
    for field = reshape(newFields(~ismember(newFields, fieldnames(structIn))), 1, [])
        structIn.(field{:}) = [];
    end
end

end