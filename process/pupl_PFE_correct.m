
function out = pupl_PFE_correct(EYE, varargin)

% Some notes
%   For the input:
%       The origin is the top left side of the computer screen
%       Positive y-direction is downward
%       Positive x-direction is rightward
%       Positive z-direction is outward from the screen (going from screen to eye)
%   To use the Hayes & Petrov formula:
%       The origin is the pupil
%       Positive y-direction is upward
%       Positive z-direction is in toward the screen
%   This code handles the conversion

if nargin == 0
    out = getargs;
else
    out = sub_PFE_correct(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'thresh' []
});

end

function outargs = getargs(varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.thresh)
    args.thresh = inputdlg(...
        sprintf('Min. value of cos theta to correct for?\n\nE.g. 0.84 = 45deg camera-eye-target angle\n'));
    if isempty(args.thresh)
        return
    else
        args.thresh = args.thresh{:};
    end
end

outargs = args;
fprintf('Applying PFE correction...\n');

end

function EYE = sub_PFE_correct(EYE, varargin)

% Input checks
if ~strcmp(EYE.units.pupil{1}, 'diameter')
    error('Pupil size is measured by %s, not diameter. PFE correction requires diameter measurements', EYE.units.pupil{1});
end

args = parseargs(varargin{:});

for side = {'left' 'right'}
    % Set pupil location to the origin
    P = EYE.coords.(side{:});
    % Gaze target coords
    T = EYE.gaze; % Assumed the same for both eyes
    T.z = P.z;
    T.x = G.x - P.x;
    T.y = -(G.y - P.y);
    % Camera coords
    C = EYE.coords.camera;
    C.x = C.y - P.y;
    C.y = -(C.y - P.y);
    C.z = P.z;
    % Compute PFE
    numerator = (C.x.*T.x + C.y.*T.y + C.z.*T.z);
    denominator = sqrt(C.x.^2 + C.y.^2 + C.z.^2) .* sqrt(T.x.^2 + T.y.^2 + T.x.^2);
    pfe = numerator ./ denominator;
    badidx = pfe < args.thresh;
    pfe(badidx) = nan;
    % Correct for PFE
    EYE.pupil.(side{:}) = EYE.pupil.(side{:}) ./ pfe;
end

end