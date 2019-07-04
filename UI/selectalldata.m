
function selectalldata

global userInterface;
ud = get(userInterface, 'UserData');
idx = ud.activeEyeDataIdx;
if all(idx)
    idx = false(size(idx));
    newt = '>';
else
    idx = true(size(idx));
    newt = '_';
end
ud.activeEyeDataIdx = idx;
set(userInterface, 'UserData', ud);
uic = findobj(userInterface, 'Tag', 'selectAllData');
currlab = get(uic, 'Label');
set(uic, 'Label', [newt ' ' currlab(3:end)]);

preservelayout
update_UI

end