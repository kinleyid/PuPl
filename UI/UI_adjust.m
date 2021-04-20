
function h = UI_adjust(h)
% Make things look nice in octave

global pupl_globals
if ~pupl_globals.isoctave
    return
end

switch lower(get(h, 'Type'))
    case 'uipanel'
        set(h, 'FontSize', 4);
end


end