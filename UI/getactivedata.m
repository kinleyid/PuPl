function out = getactivedata

global pupl_globals

out = subsref(...
    evalin('base', pupl_globals.datavarname),...
    struct(...
        'type', '()',...
        'subs', {{logical(getfield(get(pupl_globals.UI, 'UserData'), 'activeEyeDataIdx'))}}...
    )...
);

end