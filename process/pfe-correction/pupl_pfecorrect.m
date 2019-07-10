
function EYE = pupl_pfecorrect(EYE, varargin)

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

p = inputParser;
addParameter(p, 'thresh', []);
parse(p, varargin{:});

if isempty(p.Results.thresh)
    thresh = inputdlg(...
        sprintf('Min. value of cos theta to correct for?\n\nE.g. 0.84 = 45deg camera-eye-target angle\n'));
    if isempty(thresh)
        return
    end
else
    thresh = p.Results.thresh;
end

fprintf('Applying PFE correction...\n');

for dataidx = 1:numel(EYE)
    for side = {'left' 'right'}
        % Set pupil location to the origin
        P = EYE(dataidx).coords.(side{:});
        % Gaze target coords
        T = EYE(dataidx).gaze; % Assumed the same for both eyes
        T.z = P.z;
        T.x = G.x - P.x;
        T.y = -(G.y - P.y);
        % Camera coords
        C = EYE(dataidx).coords.camera;
        C.x = C.y - P.y;
        C.y = -(C.y - P.y);
        C.z = P.z;
        % Compute PFE
        numerator = (C.x.*T.x + C.y.*T.y + C.z.*T.z);
        denominator = sqrt(C.x.^2 + C.y.^2 + C.z.^2) .* sqrt(T.x.^2 + T.y.^2 + T.x.^2);
        pfe = numerator ./ denominator;
        badidx = pfe < thresh;
        pfe(badidx) = nan;
        % Correct for PFE
        EYE(dataidx).diam.(side{:}) = EYE(dataidx).diam.(side{:}) ./ pfe;
    end
end

end