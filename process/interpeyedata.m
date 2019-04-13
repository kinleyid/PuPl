function EYE = interpeyedata(EYE, varargin)

p = inputParser;
addParameter(p, 'maxlen', []);
parse(p, varargin{:});

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);
if isempty(p.Results.maxlen)
    prompt = 'Max length of data to interpolate';
    maxlen = inputdlg(prompt, prompt, [1 50], {'500ms'});
    if isempty(maxlen)
        EYE = [];
        return
    else
        maxlen = maxlen{:};
    end
else
    maxlen = p.Results.maxlen;
end
callStr = sprintf('%s''maxlen'', %s)', callStr, all2str(maxlen));

fprintf('Interpolating max. %s of missing data\n', maxlen)
for dataidx = 1:numel(EYE)
    currn = round(parsetimestr(maxlen, EYE(dataidx).srate)*EYE(dataidx).srate);
    fprintf('\t%s: interpolating max. %d missing data points\n', EYE(dataidx).name, currn)
    for field = reshape(fieldnames(EYE(dataidx).diam), 1, [])
        fprintf('\t\t%s: ', field{:});
        EYE(dataidx).diam.(field{:}) = applyinterpolation(EYE(dataidx).diam.(field{:}), currn);
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
end
fprintf('Done\n');

end

function v = applyinterpolation(v, n)

interpidx = identifyconsecutive(v, n, @isnan);

fprintf('%0.5f%% of data interpolated\n', 100*nnz(interpidx)/numel(interpidx))

v(interpidx) = interp1(find(~interpidx), v(~interpidx), find(interpidx) );

end