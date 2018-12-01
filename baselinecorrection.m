function EYE = baselinecorrection(EYE, baselineDescriptions, correctionType)

for dataIdx = 1:numel(EYE)
    fprintf('Baseline correcting %s...', EYE(dataIdx).name);
    dataStreams = fieldnames(EYE(dataIdx).data);
    for bIdx = 1:numel(baselineDescriptions)
        latencies = getlatenciesfromspandescription(EYE(dataIdx),...
            baselineDescriptions(bIdx));
        epochsToCorrect = find(ismember({EYE(dataIdx).epoch.name},...
            baselineDescriptions(bIdx).epochsToCorrect));
        if numel(latencies) > 1 && numel(latencies) ~= numel(epochsToCorrect)
            error('epochs and baselines are not lining up');
        else
            baselineCount = 0;
            epochCount = 0;
            while true
                epochCount = epochCount + 1;
                baselineCount = min(baselineCount + 1, numel(latencies));
                if epochCount > numel(epochsToCorrect)
                    break
                else
                    currLats = latencies{baselineCount};
                    epochIdx = epochsToCorrect(epochCount);
                    for stream = dataStreams(:)'
                        EYE(dataIdx).epoch(epochIdx).data.(stream{:}) = ...
                            correctionFunc(...
                                EYE(dataIdx).epoch(epochIdx).data.(stream{:}),...
                                EYE(dataIdx).data.(stream{:})(currLats),...
                                correctionType);
                    end
                end
            end
        end
    end
    fprintf('done\n')
end

end

function dataVector = correctionFunc(dataVector, baselineData, corrType)

if strcmp(corrType, 'subtract baseline mean')
    dataVector = dataVector - mean(baselineData);
elseif strcmp(corrType, 'percent change from baseline mean')
    dataVector = dataVector/mean(baselineData);
end

end