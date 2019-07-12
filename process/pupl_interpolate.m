function EYE = pupl_interpolate(EYE, varargin)

p = inputParser;
addParameter(p, 'data', []); % 'diam' or 'gaze'
addParameter(p, 'interptype', []); % 'linear' or 'spline'
addParameter(p, 'maxlen', []);
addParameter(p, 'maxdist', []);
parse(p, varargin{:});
unpack(p)

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);
if isempty(data)
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
end

if isempty(interptype)
    q = 'Use which type of interpolation?';
    a = questdlg(q, q, 'Linear', 'Cubic spline', 'Cancel', 'Linear');
    switch a
        case 'Linear'
            interptype = 'linear';
        case 'Cubic spline'
            interptype = 'spline';
        otherwise
            return
    end
end

if isempty(maxlen)
    prompt = 'Max length of data to interpolate';
    maxlen = inputdlg(prompt, prompt, [1 50], {'500ms'});
    if isempty(maxlen)
        EYE = [];
        return
    else
        maxlen = maxlen{:};
    end
end

if isempty(maxdist)
    prompt = 'Max size of jump to interpolate across';
    maxdist = inputdlg(prompt, prompt, [1 50], {'0.5`s'});
    if isempty(maxdist)
        EYE = [];
        return
    else
        maxdist = maxdist{:};
    end
end

switch interptype
    case 'linear'
        interpfunc = @interp1;
    case 'spline'
        interpfunc = @spline;
end

fprintf('Interpolating max. %s of missing data using %s interpolation\n', maxlen, interptype)
for dataidx = 1:numel(EYE)
    currn = round(parsetimestr(maxlen, EYE(dataidx).srate)*EYE(dataidx).srate);
    fprintf('\t%s: interpolating max. %d missing data points\n', EYE(dataidx).name, currn)
    for field = reshape(fieldnames(EYE(dataidx).(data)), 1, [])
        currv = EYE(dataidx).(data).(field{:}); % Current data vector
        currm = parsedatastr(maxdist, currv); % Current max distance
        fprintf('\t\t%s (max jump %.2f):', field{:}, currm);
        EYE(dataidx).(data).(field{:}) = applyinterpolation(interpfunc, currv, currn, currm);
    end
    EYE(dataidx).history{end + 1} = getcallstr(p);
end
fprintf('Done\n');

end

function v = applyinterpolation(f, v, n, m)

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

w = warning('off', 'all'); % Otherwise ugly warnings about ignoring NaN
v(interpidx) = f(find(~interpidx), v(~interpidx), find(interpidx) );
warning(w);

end