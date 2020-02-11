function out = pupl_interp(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_interp(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'data' []
    'interptype' []
    'maxlen' []
    'maxdist' []
});

end

function outargs = getargs(varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.data)
    q = 'Interpolate which type of data?';
    a = questdlg(q, q, 'Pupil size', 'Gaze', 'Cancel', 'Pupil size');
    switch a
        case 'Pupil size'
            args.data = 'pupil';
        case 'Gaze'
            args.data = 'gaze';
        otherwise
            return
    end
end

if isempty(args.interptype)
    q = 'Use which type of interpolation?';
    a = questdlg(q, q, 'Linear', 'Cubic spline', 'Cancel', 'Linear');
    switch a
        case 'Linear'
            args.interptype = 'linear';
        case 'Cubic spline'
            args.interptype = 'spline';
        otherwise
            return
    end
end

if isempty(args.maxlen)
    prompt = 'Max length of data to interpolate';
    maxlen = inputdlg(prompt, prompt, [1 50], {'500ms'});
    if isempty(maxlen)
        return
    else
        args.maxlen = maxlen{:};
    end
end

if isempty(args.maxdist)
    prompt = 'Max jump in pupil size to interpolate across';
    maxdist = inputdlg(prompt, prompt, [1 50], {'3`sd'});
    if isempty(maxdist)
        return
    else
        args.maxdist = maxdist{:};
    end
end

fprintf('Interpolating max. %s of missing data using %s interpolation\n', args.maxlen, args.interptype)
outargs = args;

end

function EYE = sub_interp(EYE, varargin)

args = parseargs(varargin{:});
switch args.interptype
    case 'linear'
        interpfunc = @interp1;
    case 'spline'
        interpfunc = @spline;
end
currn = round(parsetimestr(args.maxlen, EYE.srate)*EYE.srate);
fprintf('interpolating max. %d missing data points\n', currn)
for field = reshape(fieldnames(EYE.(args.data)), 1, [])
    currv = EYE.(args.data).(field{:}); % Current data vector
    currm = parsedatastr(args.maxdist, currv); % Current max distance
    fprintf('\t\t%s (max jump %.2f): ', field{:}, currm);
    EYE.(args.data).(field{:}) = applyinterpolation(interpfunc, currv, currn, currm);
end

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
