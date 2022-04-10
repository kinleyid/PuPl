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
        'Pupil data missing' sprintf('%f %%', 100 * eyedata(dataidx).ppnmissing)
    }';
    txt = [sprintf('%s: %s\n', txt{1:end - 1}) sprintf('%s: %s', txt{end})];
    set(children(panelidx), 'ToolTipString', txt);
end
set(userInterface, 'UserData', UserData);

%% Activate or deactivate UI menu elements

allMenus = findobj('Parent', userInterface, 'Type', 'uimenu');
for currMenu = reshape(allMenus, 1, [])
    recursiveupdatemenu(currMenu);
end

%% Update text of undo/redo buttons

timeline_idx = find(strcmp(pupl_globals.timeline.data, 'curr'));
undo_idx = timeline_idx - 1;
redo_idx = undo_idx + 1;

if undo_idx == 0
    undo_txt = '';
else
    undo_txt = sprintf(' %s', pupl_globals.timeline.txt{undo_idx});
end
undo_txt = regexprep(undo_txt, 'pupl_', '');
undo_txt = regexprep(undo_txt, '_', ' ');
undo_button = findobj(pupl_globals.UI, 'Tag', 'undo');
set(undo_button, 'Label', sprintf('&Undo%s', undo_txt));

if redo_idx > numel(pupl_globals.timeline.txt)
    redo_txt = '';
else
    redo_txt = sprintf(' %s', pupl_globals.timeline.txt{redo_idx});
end
redo_txt = regexprep(redo_txt, 'pupl_', '');
redo_txt = regexprep(redo_txt, '_', ' ');
undo_button = findobj(pupl_globals.UI, 'Tag', 'redo');
set(undo_button, 'Label', sprintf('&Redo%s', redo_txt));

%% Redraw the UI

set(userInterface, 'Visible', 'off');
set(userInterface, 'Visible', 'on');

end

function recursiveupdatemenu(currMenu)

ud = get(currMenu, 'UserData');

% Menu callbacks may be subbed out for messages informing the user of why
% the menu option is currently unavailable. Therefore the original
% callbacks need to be stored somewhere persistent so that they can be
% subbed back in once their menu becomes available again
if ~isfield(ud, 'CallbackWhenEnabled')
    ud.CallbackWhenEnabled = get(currMenu, 'Callback');
end
% When a menu option is unenabled, its children have to be hidden---if it
% still has children, it will fire a callback *even when only hovered
% over*. This results in many annoying message boxed being displayed.
if ~isfield(ud, 'ChildrenWhenEnabled')
    ud.ChildrenWhenEnabled = get(currMenu, 'Children');
end
% Assume the menu is enabled from the get-go
if ~isfield(ud, 'enabled')
    ud.enabled = true;
end

if strcmp(get(currMenu, 'Tag'), 'Preprocess')
    x = 10;
end

unenable = false; % Assume the menu does not need to be unenabled
if isfield(ud, 'CheckEnableFunction')
    % Check whether the menu should be enabled or unenabled
    try
        if feval(ud.CheckEnableFunction)
            if ~ud.enabled
                ud.enabled = true;
                set(currMenu, 'ForegroundColor', 'k');
                set(currMenu, 'Callback', ud.CallbackWhenEnabled);
                for childidx = numel(ud.ChildrenWhenEnabled):-1:1
                    set(ud.ChildrenWhenEnabled(childidx), 'Parent', currMenu);
                end
            end
        else
            unenable = true;
        end
    catch
        unenable = true;
    end
end
if unenable
    if ud.enabled
        ud.enabled = false;
        set(currMenu, 'ForegroundColor', [0.5 0.5 0.5]); % Gray out the menu
        for childidx = 1:numel(ud.ChildrenWhenEnabled)
            set(ud.ChildrenWhenEnabled(childidx), 'Parent', findobj('Tag', 'pupl:hidden-menu'));
        end
        set(currMenu, 'Callback', @(h, e)(msgbox(getfield(get(h, 'UserData'), 'msg'))));
    end
end

set(currMenu, 'UserData', ud);

for newMenu = reshape(get(currMenu, 'Children'), 1, [])
    recursiveupdatemenu(newMenu);
end

end