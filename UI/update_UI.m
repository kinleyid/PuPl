function update_UI

% Update UI panels when new data is loaded or the active datasets change

global userInterface eyeData
activeEyeDataPanel = findobj(userInterface, 'Tag', 'activeEyeDataPanel');

if userInterface.UserData.dataCount ~= numel(eyeData)
    % Data added or deleted
    userInterface.UserData.dataCount = numel(eyeData);
    preservelayout
end

for i = 1:numel(activeEyeDataPanel.Children)
    userInterface.UserData.activeEyeDataIdx(numel(activeEyeDataPanel.Children) + 1 - i) = ...
        logical(activeEyeDataPanel.Children(i).Value);
end

% Inactivate or activate UI menu elements

allMenus = findobj('parent', userInterface);

for currMenu = reshape(allMenus, 1, [])
    recursiveupdatemenu(currMenu);
end

userInterface.Visible = 'off';
userInterface.Visible = 'on';

end

function recursiveupdatemenu(currMenu)

if strcmp(currMenu.Type, 'uimenu')
    if ~isempty(currMenu.UserData)
        if feval(currMenu.UserData)
            set(currMenu, 'Enable', 'on');
        else
            set(currMenu, 'Enable', 'off');
        end
    end
end

for newMenu = reshape(currMenu.Children, 1, [])
    recursiveupdatemenu(newMenu);
end

end