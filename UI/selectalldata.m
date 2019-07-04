
function selectalldata

global userInterface;
ud = get(userInterface, 'UserData');
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
set(userInterface, 'UserData', ud);
uic = findobj(userInterface, 'Tag', 'selectAllData');
set(uic, 'Label', [newt ' &all data']);

preservelayout
update_UI

end