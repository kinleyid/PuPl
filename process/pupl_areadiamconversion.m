
function out = pupl_areadiamconversion(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    args = pupl_args2struct(varargin, {
        'to' []
    });
    switch args.to
        case 'diameter'
            EYE = structfun(@(x) sqrt(x * 4/pi), EYE.diam);
        case 'area'
            EYE = structfun(@(x) x.^2 * pi/4, EYE.diam);
    end
    % Adjust units
    EYE.units.diam{1} = args.to;
    if ~strcmp(EYE.units.diam{2}, 'px')
        switch args.to
            case 'diameter'
                [s, e] = regexp(EYE.units.diam{2}, '^2');
                if ~isempty(s)
                    EYE.units.diam{2}(s:e) = [];
                end
            case 'area'
                s = regexp(EYE.units.diam{2}, '^2', 'once');
                if isempty(s)
                    EYE.units.diam{2}(end+1:end+2) = '^2';
                end
        end
    end
end

end

function out = getargs(EYE, varargin)

out = pupl_args2struct(varargin, {
    'to' []
});

end
