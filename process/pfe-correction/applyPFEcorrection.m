function EYE = applyPFEcorrection(EYE, coords)

costheta = PFEcostheta(coords, EYE.gaze.x, EYE.gaze.y);
costheta(costheta < 0) = nan;
EYE.data = structfun(@(d) d./sqrt(costheta), EYE.data, 'un', 0);

end