function EYE = interpeyedata(EYE, varargin)

p = inputParser;
addParameter(p, 'data', []); % 'diam' or 'gaze'
addParameter(p, 'maxlen', []);
addParameter(p, 'maxdist', []);
parse(p, varargin{:});

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);
if isempty(p.Results.data)
    q = 'Interpolate which type of data?';
    a = questdlg(q, q, 'Pupil diameter', 'Gaze', 'Cancel', 'Pupil diameter');
    switch a
        case 'Pupil diameter'
            data = 'diam';
        case 'Gaze'
            data = 'gaze';
        otherwise
            return
    end
else
    data = p.Results.data;
end
callStr = sprintf('%s''data'', %s, ', callStr, all2str(data));

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
callStr = sprintf('%s''maxlen'', %s, ', callStr, all2str(maxlen));

if isempty(p.Results.maxdist)
    prompt = 'Max size of jump to interpolate across';
    maxdist = inputdlg(prompt, prompt, [1 50], {'0.5sd'});
    if isempty(maxdist)
        EYE = [];
        return
    else
        maxdist = maxdist{:};
    end
else
    maxdist = p.Results.maxdist;
end
callStr = sprintf('%s''maxdist'', %s)', callStr, all2str(maxlen));

fprintf('Interpolating max. %s of missing data\n', maxlen)
for dataidx = 1:numel(EYE)
    currn = round(parsetimestr(maxlen, EYE(dataidx).srate)*EYE(dataidx).srate);
    fprintf('\t%s: interpolating max. %d missing data points\n', EYE(dataidx).name, currn)
    for field = reshape(fieldnames(EYE(dataidx).(data)), 1, [])
        currv = EYE(dataidx).(data).(field{:}); % Current data vector
        currm = parsedatastr(maxdist, currv); % Current max distance
        fprintf('\t\t%s (max jump %.2f):', field{:}, currm);
        EYE(dataidx).(data).(field{:}) = applyinterpolation(currv, currn, currm);
    end
    EYE(dataidx).history{end + 1} = callStr;
end
fprintf('Done\n');

end

function v = applyinterpolation(v, n, m)

interpidx = identifyconsecutive(v, n, @isnan);
s = find([false diff(interpidx) == 1]);
e = find([diff(interpidx) == -1 false]);
if ~isempty(s) && ~isempty(e)
    if s(1) > e(1)
        e(1) = [];
    end
    if s(end) > e(end)
        s(end) = [];
    end
    for ii = 1:numel(s)
        if abs(v(s(ii)) - v(e(ii))) > m
            interpidx(s(ii):e(ii)) = false;
        end
    end
end

fprintf('%0.5f%% of data interpolated\n', 100*nnz(interpidx)/numel(interpidx))

v(interpidx) = interp1(find(~interpidx), v(~interpidx), find(interpidx) );

end