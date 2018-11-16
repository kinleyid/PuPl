function structArray = fieldconsistency(structArray, structIn)

if ~isempty(structArray)
    newFields = fieldnames(structIn);
    for idx = 1:numel(structArray)
        for field = reshape(newFields(~ismember(newFields, fieldnames(structArray(idx)))), 1, [])
            structArray(idx).(field{:}) = [];
        end
    end
end

end