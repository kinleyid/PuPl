function EYE = mergelr(EYE, varargin)

callStr = sprintf('eyeData = %s(eyeData)', mfilename);

fprintf('Merging left and right streams\n');

for dataIdx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataIdx).name)
    EYE(dataIdx).diam.both = mean(...
        cat(1, EYE(dataIdx).diam.left,...
        EYE(dataIdx).diam.right), 1);
    for epochIdx = 1:numel(EYE(dataIdx).epoch)
        EYE(dataIdx).epoch(epochIdx).diam.both = mean([
            EYE(dataIdx).epoch(epochIdx).diam.left
            EYE(dataIdx).epoch(epochIdx).diam.right]);
    end
    for binIdx = 1:numel(EYE(dataIdx).bin)
        EYE(dataIdx).bin(binIdx).data.both = mean(...
            cat(3, EYE(dataIdx).bin(binIdx).data.left,...
                EYE(dataIdx).bin(binIdx).data.right), 3);
    end
    fprintf('done\n')
    EYE(dataIdx).history = cat(1, EYE(dataIdx).history, callStr);
end
fprintf('Done\n')
end