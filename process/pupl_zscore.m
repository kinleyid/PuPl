
function out = pupl_zscore(EYE)
% Z-score pupil size data
%
% Example:
%   pupl_zscore(eye_data)
if nargin == 0
    out = [];
else
    EYE = pupl_proc(EYE, @(x) (x - nanmean_bc(x)) / nanstd_bc(x));
    EYE.ur = pupl_proc(EYE.ur, @(x) (x - nanmean_bc(x)) / nanstd_bc(x));
    EYE.units.pupil(2:3) = {'z-scores' 'absolute'};
    out = EYE;
end

end
