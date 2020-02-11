
function out = pupl_units(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_units(EYE, varargin);
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'data' [] % pupl or gaze
    'to' []
    'fac' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.data)
    q = 'Perform unit conversion on which unit type?';
    a = questdlg(q, q, 'Pupil size', 'Gaze', 'Cancel', 'Pupil size');
    switch a
        case 'Pupil size'
            args.data = 'diam';
        case 'Gaze'
            args.data = 'gaze';
    end
end

if isempty(args.to)
    args.to = inputdlg(sprintf('Convert current measurements (in %s) to what units?', EYE(1).units.(args.data){2}));
    if isempty(args.to)
        return
    else
        args.to = args.to{:};
    end
end

if isempty(args.fac)
    args.fac = inputdlg(sprintf('How many %s per %s?', args.to, EYE(1).units.(args.data){2}));
    if isempty(args.fac)
        return
    else
        args.to = args.fac{:};
    end
end

outargs = args;

end

function EYE = sub_units(EYE, varargin)

args = parseargs(varargin{:});

switch args.data
    case 'gaze'
        EYE.units.gaze.x{2} = args.to;
        EYE.units.gaze.y{2} = args.to;
    otherwise
        
end

end
