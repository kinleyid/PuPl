function update_UI

% Update UI panels when new data is loaded or the active datasets change

global pupl_globals
userInterface = pupl_globals.UI;
eyedata = evalin('base', pupl_globals.datavarname);
activeEyeDataPanel = findobj(userInterface, 'Tag', 'activeEyeDataPanel');

UserData = get(userInterface, 'UserData');
if UserData.dataCount ~= numel(eyedata)
    % Data added or deleted
    UserData.dataCount = numel(eyedata);
    set(userInterface, 'UserData', UserData);
    preservelayout
end
set(userInterface, 'UserData', UserData);

%% Set activeidx to checkbox values and tooltips

UserData = get(userInterface, 'UserData');
children = get(activeEyeDataPanel, 'Children');
for i = 1:numel(children)
    % Set activeidx
    UserData.activeEyeDataIdx(numel(children) + 1 - i) = ...
        logical(get(children(i), 'Value'));
    % Set tooltip
    txt = {
        'Name' sprintf('%s', eyedata(i).name)
        'Sample rate' sprintf('%d Hz', eyedata(i).srate)
        'Recording length' sprintf('%f mins', eyedata(i).ndata / eyedata(i).srate / 60)
        'N. events' sprintf('%d', numel(eyedata(i).event))
        'N. epochs' sprintf('%d', numel(eyedata(i).epoch))
        'Pupil data missing' sprintf('%f %%',...
            100*(nnz(isnan(eyedata(i).pupil.left)) + nnz(isnan(eyedata(i).pupil.right)))/(2*eyedata(i).ndata))
    }';
    txt = [sprintf('%s: %s\n', txt{1:end - 1}) sprintf('%s: %s', txt{end})];
    set(children(i), 'ToolTipString', txt);
end
set(userInterface, 'UserData', UserData);

%% Inactivate or activate UI menu elements on the basis of whether

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
        set(currMenu, 'Enable', 'off');
        try
            if feval(get(currMenu, 'UserData'))
                set(currMenu, 'Enable', 'on');
            end
        end
    end
end

for newMenu = reshape(get(currMenu, 'Children'), 1, [])
    recursiveupdatemenu(newMenu);
end

end