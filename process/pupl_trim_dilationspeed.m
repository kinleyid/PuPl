
function out = pupl_trim_dilationspeed(EYE, varargin)
% Trims data based on dilation speed
%
% Citation:
% Kret, M. E., & Sjak-Shie, E. E. (2019). Preprocessing pupil size data:
% Guidelines and code. Behavior research methods, 51(3), 1336-1342.
%
% Inputs:
%   thresh: string
%       computes the dilation speed threshold, above which data will be
%       removed
% Example:
%   pupl_trim_dilationspeed(eye_data,...
%       'thresh', '`md + 5`madv');
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
        'defthresh', '`md + 5`madv',...
        'names', allnames);
    if isempty(args.thresh)
        return
    end
end

outargs = args;
fprintf('Valid dilation speed samples are less than %s\n', args.thresh);

end

function EYE = sub_trim_dilationspeed(EYE, varargin)

args = parseargs(varargin{:});

for field = reshape(fieldnames(EYE.pupil), 1, [])
    data = EYE.pupil.(field{:});
    badidx = trim_ds(data, args.thresh);
    badidx = badidx & ~isnan(data);
    data(badidx) = nan;
    EYE.pupil.(field{:}) = data;
    fprintf('%s:\t%f%% previously extant data removed\n', field{:}, 100*nnz(badidx)/numel(badidx));
end

end

function badidx = trim_ds(x, thresh)

dp = dprime(x);
currthresh = parsedatastr(thresh, dp);
badidx = dp >= currthresh;

end

function dp = dprime(x)

ad = abs(diff(x));
dp = [ad(1) max([ad(1:end-1); ad(2:end)]) ad(end)];

end
