function EYE = trimshort(EYE, varargin)

p = inputParser;
addParameter(p, 'timearg', []);
parse(p, varargin{:});

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);
if isempty(p.Results.timearg)
    prompt = 'Trim islands of data shorter than or equal to:';
    timearg = inputdlg(prompt, prompt, [1 50], {'100ms'});
    if isempty(timearg)
        EYE = [];
        return
    end
    timearg = timearg{:};
else
    timearg = p.Results.timearg;
end
callStr = sprintf('%s''timearg'', %s)', callStr, all2str(timearg));

fprintf('Trimming islands of data shorter than or equal to %s\n', timearg);

for dataidx = 1:numel(EYE)
    n = round(parsetimestr(timearg, EYE(dataidx).srate)*EYE(dataidx).srate);
    fprintf('\t%s: trimming islands of data shorter than or equal to %d samples\n', EYE(dataidx).name, n);
    for field = reshape(fieldnames(EYE(dataidx).diam), 1, [])
        trimidx = identifyconsecutive(EYE(dataidx).diam.(field{:}), n, @(x) ~isnan(x));
        fprintf('\t\t%s: %0.2f%% removed\n', field{:}, 100*nnz(trimidx)/numel(trimidx));
        EYE(dataidx).diam.(field{:})(trimidx) = nan;
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
end
fprintf('Done\n')

end