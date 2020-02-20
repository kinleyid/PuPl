
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

if isempty(args.mmdims) || isempty(args.pxdims)
    units = mergefields(EYE, 'units', 'gaze', {'x' 'y'});
    if ~any(strcmp(units(2:3:end), 'px'))
        uiwait(msgbox('Gaze is already measured in units of mm'));
    else
        if isempty(args.mmdims)
            args.mmdims = inputdlg({
                'Display width (mm)'
                'Display height (mm)'});
            if isempty(args.mmdims)
                return
            end
            args.mmdims = str2double(args.mmdims);
        end

        if isempty(args.pxdims)
            args.pxdims = inputdlg({
                'Display width (px)'
                'Display height (px)'});
            if isempty(args.pxdims)
                return
            end
            args.pxdims = str2double(args.pxdims);
        end
    end
end
if isempty(args.flipy)
    if any(strcontains(mergefields(EYE, 'units', 'gaze', 'y'), 'bottom'))
        q = 'Re-reference gaze y coordinates to the top of the display?';
        a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
        switch lower(a)
            case 'yes'
                args.flipy = true;
            case 'no'
                args.flipy = false;
            otherwise
                return
        end
        if isempty(args.mmdims)
            args.mmdims = inputdlg('Display height (mm)');
            if isempty(args.mmdims)
                return
            end
            args.mmdims = [nan str2double(args.mmdims)];
        end
    else
        uiwait(msgbox('Gaze y coordinates are already referenced to the top of the display'));
    end
end

if all(structfun(@isempty, args))
    args = [];
end
outargs = args;

end

function EYE = sub_px2mm(EYE, varargin)

args = parseargs(varargin{:});

if strcmp(EYE.units.gaze.x{2}, 'px')
    EYE.gaze.x = EYE.gaze.x * args.mmdims(1) / args.pxdims(1);
    EYE.units.gaze.x{2} = 'mm';
end
if strcmp(EYE.units.gaze.y{2}, 'px')
    EYE.gaze.y = EYE.gaze.y * args.mmdims(2) / args.pxdims(2);
    EYE.units.gaze.y{2} = 'mm';
end
if args.flipy
    % Rereference to the top of the screen
    EYE.gaze.y = args.mmdims(2) - EYE.gaze.y;
    % Update units
    [s, e] = regexp(EYE.units.gaze.y{3}, 'bottom');
    EYE.units.gaze.y{3} = [EYE.units.gaze.y{3}(1:s-1) 'top' EYE.units.gaze.y{3}(e+1:end)];
end

end