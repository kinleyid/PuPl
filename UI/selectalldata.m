
function selectalldata

global pupl_globals;
ud = get(pupl_globals.UI, 'UserData');
idx = ud.activeEyeDataIdx;
dim = size(idx);
if all(idx)
    idx = false(dim);
    newt = 'Select';
else
    idx = true(dim);
    newt = 'Deselect';
end
ud.activeEyeDataIdx = idx;
set(pupl_globals.UI, 'UserData', ud);
uic = findobj(pupl_globals.UI, 'Tag', 'selectAllData');
set(uic, 'Label', [newt ' &all data']);

preservelayout
update_UI

end