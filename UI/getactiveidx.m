
function out = getactiveidx

global pupl_globals;
out = getfield(get(pupl_globals.UI, 'UserData'), 'activeEyeDataIdx');

end