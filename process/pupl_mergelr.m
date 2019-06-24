function EYE = pupl_mergelr(EYE, varargin)

callStr = sprintf('eyeData = %s(eyeData)', mfilename);

fprintf('Merging left and right streams\n');

for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name)
    EYE(dataidx).diam.both = mergelr(EYE(dataidx));
    for epochidx = 1:numel(EYE(dataidx).epoch)
        EYE(dataidx).epoch(epochidx).diam.both = mergelr(EYE(dataidx).epoch(epochidx));
    end
    for binidx = 1:numel(EYE(dataidx).bin)
        EYE(dataidx).bin(binidx).data.both = mean(...
            cat(3, EYE(dataidx).bin(binidx).data.left,...
                EYE(dataidx).bin(binidx).data.right), 3);
    end
    fprintf('done\n')
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
end
fprintf('Done\n')
end