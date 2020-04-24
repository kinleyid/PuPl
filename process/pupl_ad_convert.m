
function out = pupl_ad_convert(EYE, varargin)
% Convert pupil diameter to area and vice versa
%
% Inputs:
%   to: string
%       'diameter' or 'area'
% Example:
%   pupl_ad_convert(eye_data,...
%       'to', 'diameter')
if nargin == 0
    out = @getargs;
else
    args = pupl_args2struct(varargin, {
        'to' []
    });
    if strcmp(EYE.units.pupil{1}, args.to)
        error('Pupil size is already measured as %s', args.to);
    end
    switch args.to
        case 'diameter'
            EYE = pupl_proc(EYE, @(x) sqrt(x * 4/pi));
        case 'area'
            EYE = pupl_proc(EYE, @(x) x.^2 * pi/4);
    end
    % Adjust units
    EYE.units.pupil{1} = args.to;
    out = EYE;
end

end

function out = getargs(varargin)

out = pupl_args2struct(varargin, {
    'to' []
});

end
