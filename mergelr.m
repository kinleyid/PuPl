function EYE = mergelr(EYE)

for dataIdx = 1:numel(EYE)
    EYE.data.both = mean([
        EYE.data.left
        EYE.data.right], 1, 'omitnan');
end

end