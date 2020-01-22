function preservelayout(varargin)

sep = 2;
buttonHeight = 20;

global pupl_globals
eyeData = evalin('base', pupl_globals.datavarname);
userInterface = pupl_globals.UI;

currData = eyeData;
dataPanel = findobj(userInterface, 'tag', 'activeEyeDataPanel');
activeIdx = getfield(get(userInterface, 'UserData'), 'activeEyeDataIdx');
if ~isempty(get(dataPanel, 'Children'))
    delete(get(dataPanel, 'Children'));
end
activeIdx(numel(activeIdx)+1:numel(currData)) = true;

dataPanelPixelPos = getDataPanelPixelPos;
top = dataPanelPixelPos(4) - buttonHeight;
buttonWidth = dataPanelPixelPos(3) - sep;
lowestButtonPos = top - (buttonHeight + sep)*numel(currData);
if lowestButtonPos < dataPanelPixelPos(2)
    % Extend user interface if there is enough data to do so
    dataPanelRelPos = get(dataPanel, 'Position');
    d = 0.5;
    dataPanelRelPos(2) = dataPanelRelPos(2) - d;
    dataPanelRelPos(4) = dataPanelRelPos(4) + d;
    set(dataPanel, 'Position', dataPanelRelPos);
    ud = get(dataPanel, 'UserData');
    ud.OriginalPos(2) = ud.OriginalPos(2) - d;
    ud.OriginalPos(4) = ud.OriginalPos(4) + d;
    set(dataPanel, 'UserData', ud);
    dataPanelPixelPos = getDataPanelPixelPos;
    top = dataPanelPixelPos(4) - buttonHeight;
    buttonWidth = dataPanelPixelPos(3) - sep;
else
    % Shorten user interface
end

for dataidx = 1:numel(currData)
    if activeIdx(dataidx)
        value = 1;
    else
        value = 0;
    end
    currPos = [sep, top - (buttonHeight+sep)*dataidx, buttonWidth, buttonHeight];
    uicontrol(dataPanel,...
        'Style', 'checkbox',...
        'Position', currPos,...
        'String', currData(dataidx).name,...
        'Value', value,...
        'FontSize', 10,...
        'KeyPressFcn', @(h, e) enterdo(e, {
            @() set(h, 'Value', switch01(get(h, 'Value')))
            @update_UI}),...
        'Callback', @(h, e) update_UI);
end

UserData = get(userInterface, 'UserData');
UserData.activeEyeDataIdx = activeIdx;
set(userInterface, 'UserData', UserData);

end

function out = switch01(in)

if in == 1
  out = 0;
elseif in == 0
  out = 1;
end

end

function dataPanelPixelPos = getDataPanelPixelPos
global pupl_globals
userInterface = pupl_globals.UI;
dataPanelPixelPos = getPixelPos(...
    get(userInterface, 'position'),...
    get(findobj(userInterface, 'Tag', 'activeEyeDataPanel'), 'position'));
%{
absContPos = getPixelPos(...
    get(userInterface, 'position'),...
    get(findobj(userInterface, 'Tag', 'outerContainerPanel'), 'position'));
absContPos = getPixelPos(...
    absContPos,...
    get(findobj(userInterface, 'Tag', 'containerPanel'), 'position'));
dataPanelPixelPos = getPixelPos(...
    absContPos,...
    get(findobj(userInterface, 'Tag', 'activeEyeDataPanel'), 'position'));
%}
end

function childPixelPos = getPixelPos(parentPixelPos, childRelPos)

childPixelPos = [];
for ii = [3 4]
    childPixelPos(ii) = parentPixelPos(ii) * childRelPos(ii);
end
for ii = [1 2]
    childPixelPos(ii) = parentPixelPos(ii) + childRelPos(ii) * parentPixelPos(ii + 2);
end

end