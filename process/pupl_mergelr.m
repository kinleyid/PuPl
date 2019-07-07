function EYE = pupl_mergelr(EYE, varargin)

callStr = sprintf('eyeData = %s(eyeData)', mfilename);

fprintf('Merging left and right streams\n');

for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name)
    EYE(dataidx).diam.both = mergelr(EYE(dataidx));
    for epochidx = 1:numel(EYE(dataidx).epoch)
        EYE(dataidx).epoch(epochidx).diam.both = mergelr(EYE(dataidx).epoch(epochidx));
    end
    fprintf('done\n')
    EYE(dataidx).history{end + 1} = callStr;
end
fprintf('Done\n')
end