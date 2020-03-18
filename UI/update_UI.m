function update_UI

% Update UI panels when new data is loaded or the active datasets change

global pupl_globals
userInterface = pupl_globals.UI;
eyedata = evalin('base', pupl_globals.datavarname);
activeEyeDataPanel = findobj(userInterface, 'Tag', 'activeEyeDataPanel');

UserData = get(userInterface, 'UserData');
if UserData.dataCount ~= numel(eyedata)
    % Data added or deleted
    activeIdx = UserData.activeEyeDataIdx;
    if numel(eyedata) > numel(activeIdx)
        activeIdx(numel(activeIdx)+1:numel(eyedata)) = true;
    elseif numel(eyedata) < numel(activeIdx)
        if isempty(eyedata)
            activeIdx = [];
        else
            activeIdx = activeIdx([eyedata.UI_n]);
        end
    end
    UserData.dataCount = numel(eyedata);
    UserData.activeEyeDataIdx = logical(activeIdx);
    set(userInterface, 'UserData', UserData);
    % Update UI_n in the eye data
    if ~isempty(eyedata)
        UI_n = num2cell(1:numel(eyedata));
        [eyedata.UI_n] = UI_n{:};
        assignin('base', pupl_globals.datavarname, eyedata);
    end
    % Redraw data panel
    preservelayout
end

%% Set activeidx to checkbox values and tooltips

UserData = get(userInterface, 'UserData');
children = get(activeEyeDataPanel, 'Children');
for panelidx = 1:numel(children)
    dataidx = numel(children) + 1 - panelidx;
    % Set activeidx
    UserData.activeEyeDataIdx(dataidx) = ...
        logical(get(children(panelidx), 'Value'));
    % Set tooltip
    txt = {
        'Name' sprintf('%s', eyedata(dataidx).name)
        'Sample rate' sprintf('%d Hz', eyedata(dataidx).srate)
        'Recording length' sprintf('%f mins', eyedata(dataidx).ndata / eyedata(dataidx).srate / 60)
        'N. events' sprintf('%d', numel(eyedata(dataidx).event))
        'N. epochs' sprintf('%d', numel(eyedata(dataidx).epoch))
        'Pupil data missing' sprintf('%f %%',...
            100*(nnz(isnan(eyedata(dataidx).pupil.left)) + nnz(isnan(eyedata(dataidx).pupil.right)))/(2*eyedata(dataidx).ndata))
    }';
    txt = [sprintf('%s: %s\n', txt{1:end - 1}) sprintf('%s: %s', txt{end})];
    set(children(panelidx), 'ToolTipString', txt);
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