function out = pupl_PFE_detrend(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_PFE_detrend(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'axis' []
});

end

function outargs = getargs(varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.axis)
    q = 'Detrend along which axis?';
    a = questdlg(q, q, 'x', 'y', 'Cancel', 'x');
    if strcmp(a, 'Cancel')
        return
    else
        args.axis = a;
    end
end

outargs = args;

end

function EYE = sub_PFE_detrend(EYE, varargin)

args = parseargs(varargin{:});

params = pupl_PFE_detrend_getparams(EYE, args.axis);
fprintf('Correcting for the following equation:\n\tDiam = C + ')
switch args.axis
    case 'y'
        fprintf('%f*gaze_y', params(1))
    case 'x'
        fprintf('%f*gaze_x + %f*gaze_x^2', params(2), params(1))
end
fprintf('\n')
est = polyval(params, EYE.gaze.(args.axis));
est = est - nanmean_bc(est);
EYE = pupl_proc(EYE, @(x) x - est);

end
