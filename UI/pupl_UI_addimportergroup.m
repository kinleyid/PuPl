
function pupl_UI_addimportergroup(varargin)

global pupl_globals
if isgraphics(pupl_globals.UI)
    
    args = pupl_args2struct(varargin, {
        'name' []
        'importers' []
    });
    

end