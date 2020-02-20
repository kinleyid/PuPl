
function str = pupl_getunits(EYE, varargin)

% Get string describing units
if isempty(varargin)
    cfg = {'pupil'};
else
    cfg = varargin;
end

units = mergefields(EYE, 'units');
switch cfg{1}
    case {'pupil' 'epoch'}
        if numel(units) > 1
            if ~isequal(units.(cfg{1}))
                str = 'Pupil size (inconsistent units between recordings)';
                return
            end
            units = units(1);
        end
        str = sprintf('Pupil %s (%s, %s)', units.(cfg{1}){:});
    case 'gaze'
        if numel(units) > 1
            if ~isequal(units.pupil)
                str = sprintf('Gaze %s (inconsistent units between recordings)', units(1).gaze.(cfg{2}){1});
                return
            end
            units = units(1);
        end
        str = sprintf('Gaze %s (%s, %s)', units.gaze.(cfg{2}){:});
end