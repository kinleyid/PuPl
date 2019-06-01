function update_UI

% Update UI panels when new data is loaded or the active datasets change

global userInterface eyeData
activeEyeDataPanel = findobj(userInterface, 'Tag', 'activeEyeDataPanel');

UserData = get(userInterface, 'UserData');
if UserData.dataCount ~= numel(eyeData)
    % Data added or deleted
    UserData.dataCount = numel(eyeData);
    set(userInterface, 'UserData', UserData);
    preservelayout
end
set(userInterface, 'UserData', UserData);

UserData = get(userInterface, 'UserData');
children = get(activeEyeDataPanel, 'Children');
for i = 1:numel(children)
    UserData.activeEyeDataIdx(numel(children) + 1 - i) = ...
        logical(get(children(i), 'Value'));
end
set(userInterface, 'UserData', UserData);

% Inactivate or activate UI menu elements

allMenus = findobj('parent', userInterface);

for currMenu = reshape(allMenus, 1, [])
    recursiveupdatemenu(currMenu);
end

set(userInterface, 'Visible', 'off');
set(userInterface, 'Visible', 'on');

end

function recursiveupdatemenu(currMenu)

if strcmp(get(currMenu, 'Type'), 'uimenu')
    if ~isempty(get(currMenu, 'UserData'))
        if feval(get(currMenu, 'UserData'))
            set(currMenu, 'Enable', 'on');
        else
            set(currMenu, 'Enable', 'off');
        end
    end
end

for newMenu = reshape(get(currMenu, 'Children'), 1, [])
    recursiveupdatemenu(newMenu);
end

end