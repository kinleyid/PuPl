function out = pupl_interp(EYE, varargin)
% Interpolate missing data
%
% Inputs:
%   data: string ('pupil' or 'gaze')
%       specifies which data to interpolate
%   interptype: string ('linear' or 'spline')
%       specifies which interpolation method to use
%   maxlen: string
%       specifies the maximum gap length, in terms of time, to interpolate
%       across
%   maxdist: string
%       specifies the maximum jump in data magnitude between the two ends
%       of the gap for interpolation to be valid
% Example:
%   pupl_interp(eye_data,...
%       'data', 'pupil',...
%       'interptype', 'linear',...
%       'maxlen', '400ms',...
%       'maxdist', '1`sd');
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

function outargs = getargs(EYE, varargin)

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
    maxlen = inputdlg(prompt, prompt, [1 50], {'400ms'});
    if isempty(maxlen)
        return
    else
        args.maxlen = maxlen{:};
    end
end

if isempty(args.maxdist)
    prompt = 'Max jump in pupil size to interpolate across';
    maxdist = inputdlg(prompt, prompt, [1 50], {'1`sd'});
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
    fprintf('\t%s (max jump %.2f):\n', field{:}, currm);
    EYE.(args.data).(field{:}) = applyinterpolation(interpfunc, currv, currn, currm);
end

end

function v = applyinterpolation(f, v, n, m)

interpidx = ic_fft(isnan(v), n, 'most');
s = find(diff([false, interpidx, false]) == 1);
e = find(diff([false, interpidx, false]) == -1) - 1;
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

fprintf('Before interpolation, %0.2f%% of data is missing\n', 100*nnz(isnan(v))/numel(v));
fprintf('%0.2f%% of missing data will interpolated\n', 100*nnz(interpidx)/nnz(isnan(v)));
w = warning('off', 'all'); % Otherwise ugly warnings about ignoring NaN
v(interpidx) = f(find(~interpidx), v(~interpidx), find(interpidx) );
warning(w);
fprintf('Interpolation complete. After interpolation, %0.2f%% of data is missing\n', 100*nnz(isnan(v))/numel(v));

end
