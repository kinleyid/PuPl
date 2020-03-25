
function out = pupl_downsample(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_downsample(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'fac' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.fac)
    args.fac = inputdlg('Downsample by what factor? (Integers only)');
    if isempty(args.fac)
        return
    else
        args.fac = round(str2double(args.fac));
    end
end

fprintf('Downsampling by a factor of %d\n', args.fac);
outargs = args;

end

function EYE = sub_downsample(EYE, varargin)

args = parseargs(varargin{:});

% get functions that will perform baseline correction and the new string
% that will describe the correction

ds = @(x) x(1:args.fac:end);

EYE = pupl_proc(EYE, ds, 'all');
EYE.srate = EYE.srate / args.fac;
EYE.ndata = numel(EYE.pupil.left);
EYE.times = ds(EYE.times);
EYE.datalabel = ds(EYE.datalabel);

end