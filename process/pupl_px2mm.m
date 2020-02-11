
function out = pupl_px2mm(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_px2mm(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'mmdims' []
    'pxdims' []
    'flipy' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.mmdims)
    args.mmdims = inputdlg({
        'Screen width (mm)'
        'Screen height (mm)'});
    if isempty(args.mmdims)
        return
    end
    args.mmdims = str2double(args.mmdims);
end

if isempty(args.pxdims)
    args.pxdims = inputdlg({
        'Screen width (px)'
        'Screen height (px)'});
    if isempty(args.pxdims)
        return
    end
    args.pxdims = str2double(args.pxdims);
end

if isempty(args.flipy)
    q = 'Reverse gaze y coordinates?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
    switch lower(a)
        case 'yes'
            args.flipy = true;
        case 'no'
            args.flipy = false;
        otherwise
            return
    end
end

end

function sub_px2mm(EYE, varargin)

args = parseargs(varargin{:});

EYE.gaze.x = EYE.gaze.x * args.mmdims(1) / args.pxdims(1);
EYE.units.gaze.x{2} = 'mm';
EYE.gaze.y = EYE.gaze.y * args.mmdims(2) / args.pxdims(2);
EYE.units.gaze.y{2} = 'mm';
if flipy
    EYE.gaze.y = args.mmdims(1) - EYE.gaze.y;
    EYE.coords.gaze.y{2} = 'screen bottom';
    EYE.units.gaze.y{3} = 'screen bottom';
end

end