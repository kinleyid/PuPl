
function out = pupl_trim_dilationspeed(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_trim_dilationspeed(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'thresh' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.thresh)
    % Compute d prime for all datasets
    alld = {};
    allnames = {};
    for dataidx = 1:numel(EYE)
        for stream = reshape(fieldnames(EYE(dataidx).pupil), 1, [])
            alld{end + 1} = dprime(EYE(dataidx).pupil.(stream{:}));
            allnames{end + 1} = sprintf('%s %s pupil', EYE(dataidx).name, stream{:});
        end
    end
    args.thresh = UI_cdfgetrej(alld,...
        'threshname', 'Dilation speed',...
        'names', allnames);
    if isempty(args.thresh)
        return
    end
end

outargs = args;

end

function EYE = sub_trim_dilationspeed(EYE, varargin)

args = parseargs(varargin{:});

EYE = pupl_proc(EYE, @(x) trim_ds(x, args.thresh));

end

function x = trim_ds(x, thresh)

dp = dprime(x);
currthresh = parsedatastr(thresh, dp);
isrej = dp >= currthresh;
x(isrej) = nan;

end

function dp = dprime(x)

ad = abs(diff(x));
dp = [ad(1) max([ad(1:end-1); ad(2:end)]) ad(end)];

end
