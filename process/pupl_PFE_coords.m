
function out = pupl_PFE_coords(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    EYE.coords = parseargs(varargin{:});
    out = EYE;
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'camera' []
    'left' []
    'right' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

objs = {
    {'camera' 'Camera'}
    {'left' 'Left pupil'}
    {'right' 'Right pupil'}
};

% Display explanation
if any(structfun(@isempty, args))
    msg = {
        'NOTE'
        'Coordinates must be in millimeters'
        'The origin (x = 0, y = 0, z = 0) is the top left side of the computer screen'
        'Positive y direction is downward along the plane defined by the computer''s screen'
        'Positive x direction is rightward'
        'Positive z direction is outward from the screen (going from screen to eye)' 
    };
    f = msgbox(sprintf('%s\n', msg{:}));

    for ii = 1:size(objs, 1)
        objfield = objs{ii}{1};
        objname = objs{ii}{2};
        if isempty(args.(objfield))
            % Get default coords
            instr = {};
            axes = {'x' 'y' 'z'};
            for ax = axes
                instr{end + 1} = sprintf('%s %s (mm)', objname, ax{:});
            end
            coords = inputdlg(instr);
            if isempty(coords)
                if isgraphics(f)
                    delete(f);
                end
                return
            end
            coords = str2double(coords);
            for jj = 1:numel(axes)
                args.(objfield).(axes{jj}) = coords(jj);
            end
        end
    end
    if isgraphics(f)
        delete(f);
    end
end

outargs = args;

end