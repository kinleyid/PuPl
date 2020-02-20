
function out = pupl_ad_convert(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    args = pupl_args2struct(varargin, {
        'to' []
    });
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

function out = getargs(EYE, varargin)

out = pupl_args2struct(varargin, {
    'to' []
});

end
