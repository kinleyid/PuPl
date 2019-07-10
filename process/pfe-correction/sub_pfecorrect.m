
function x = sub_pfecorrect(coords)

P = EYE(dataidx).coords.(side{:});
% Gaze target coords
T = EYE(dataidx).gaze; % Assumed the same for both eyes
T.z = P.z;
T.x = G.x - P.x;
T.y = -(G.y - P.y);
% Camera coords
C = EYE(dataidx).coords.cam;
C.x = C.y - P.y;
C.y = -(C.y - P.y);
C.z = P.z;
% Compute PFE
numerator = (C.x.*T.x + C.y.*T.y + C.z.*T.z);
denominator = sqrt(C.x.^2 + C.y.^2 + C.z.^2) .* sqrt(T.x.^2 + T.y.^2 + T.x.^2);
pfe = numerator ./ denominator;
pfe(abs(pfe - 1) > thresh) = 1;
% Correct for PFE
EYE(dataidx).diam.(side{:}) = EYE(dataidx).diam.(side{:}) ./ pfe;

end