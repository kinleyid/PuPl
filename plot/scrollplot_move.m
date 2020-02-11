
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
a = findobj(h, 'Tag', 'ax');
ud = get(a, 'UserData');
ud.x = ud.x + change*ud.srate;
if any(ud.x < 1)
    ud.x = ud.x - min(ud.x) + 1;
end
set(a, 'UserData', ud);

scrollplot_update(a);

end