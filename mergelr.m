function EYE = mergelr(EYE, varargin)

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

fprintf('Merging left and right streams...');

for dataIdx = 1:numel(EYE)
    fprintf('dataset %d...', dataIdx)
    EYE(dataIdx).data.both = mean(...
        cat(1, EYE(dataIdx).data.left,...
        EYE(dataIdx).data.right), 1);
    for epochIdx = 1:numel(EYE(dataIdx).epoch)
        EYE(dataIdx).epoch(epochIdx).data.both = mean(...
            cat(1, EYE(dataIdx).epoch(epochIdx).data.left,...
            EYE(dataIdx).epoch(epochIdx).data.right), 1);
    end
    for binIdx = 1:numel(EYE(dataIdx).bin)
        EYE(dataIdx).bin(binIdx).data.both = mean(...
            cat(3, EYE(dataIdx).bin(binIdx).data.left,...
                EYE(dataIdx).bin(binIdx).data.right), 3);
    end
end

fprintf('done\n');

end