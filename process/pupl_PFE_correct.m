
function out = pupl_PFE_correct(EYE, varargin)

% Some notes
%   For the user-provided coordinates and the gaze point:
%       The origin is the top left side of the display
%       Positive y-direction is downward
%       Positive x-direction is rightward
%       Positive z-direction is outward from the screen (going from screen to eye)
%   To use the Hayes & Petrov formula:
%       The origin is the pupil
%       Positive x-direction is rightward
%       Positive y-direction is upward
%       Positive z-direction is in toward the screen
%   This code handles the conversion

if nargin == 0
    out = @getargs;
else
    out = sub_PFE_correct(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'minfac' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.minfac)
    args.minfac = inputdlg(...
        sprintf('To correct the pupil foreshortening error, each pupil diameter sample is divided by the cosine of the angle at which the pupil is turned away from the camera.\n\nYou may wish to define a minimum correction factor to avoid dividing pupil size measurements by very small numbers (e.g. a minimum factor of 0.7 corresponds to the pupil pointing away from the camera at an angle of approximately 45 degrees)\n\nMinimum correction factor:'));
    if isempty(args.minfac)
        return
    else
        args.minfac = str2double(args.minfac{:});
    end
end

outargs = args;
fprintf('Applying PFE correction...\n');

end

function EYE = sub_PFE_correct(EYE, varargin)

% Input checks
pupil_units = mergefields(EYE, 'units', 'pupil');
pupil_units = pupil_units(1:3:end);
badidx = ~strcmp(pupil_units, 'diameter');
if any(badidx)
    error('Pupil size is measured by %s, not diameter, as required for PFE correction.', pupil_units{find(badidx, 1)});
end

gaze_y_units = mergefields(EYE, 'units', 'gaze', 'y');
gaze_y_units = gaze_y_units(3:3:end);
badidx = ~strcontains(gaze_y_units, 'top');
if any(badidx)
    error('Gaze y is measured %s, not the top, as required for PFE correction.',...
        gaze_y_units{find(badidx, 1)});
end

gaze_units = mergefields(EYE, 'units', 'gaze', {'x' 'y'});
gaze_units = gaze_units(2:3:end);
badidx = ~strcmp(gaze_units, 'mm');
if any(badidx)
    error('Gaze y is measured in %s, not mm, as required for PFE correction.',...
        gaze_units{find(badidx, 1)});
end
args = parseargs(varargin{:});

for side = {'left' 'right'}
    % Set pupil location to the origin
    P = EYE.coords.(side{:});
    G = EYE.gaze;
    % Gaze target coords
    T = EYE.gaze; % Assumed the same for both eyes
    T.z = P.z;
    T.x = G.x - P.x;
    T.y = -(G.y - P.y);
    % Camera coords
    C = EYE.coords.camera;
    C.x = C.y - P.y;
    C.y = -(C.y - P.y);
    C.z = P.z - C.z;
    % Compute PFE
    numerator = (C.x.*T.x + C.y.*T.y + C.z.*T.z);
    denominator = sqrt(C.x.^2 + C.y.^2 + C.z.^2) .* sqrt(T.x.^2 + T.y.^2 + T.x.^2);
    pfe = numerator ./ denominator;
    badidx = pfe < args.minfac;
    pfe(badidx) = nan;
    % Correct for PFE
    EYE.pupil.(side{:}) = EYE.pupil.(side{:}) ./ pfe;
end

end