
function scrollplot_move(h, e)

switch e.Key
    case {'h', 'pageup'}
        change = -5;
    case {'l', 'pagedown'}
        change = 5;
    case {'k', 'rightarrow', 'right'}
        change = 1;
    case {'j', 'leftarrow', 'left'}
        change = -1;
    otherwise
        return
end
a = findobj('Tag', 'ax');
UserData = get(a, 'UserData');
UserData.x = UserData.x + change*UserData.srate;
if any(UserData.x < 1)
    UserData.x = UserData.x - min(UserData.x) + 1;
end
set(a, 'UserData', UserData);

scrollplot_update(a);

end