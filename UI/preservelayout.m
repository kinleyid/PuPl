function preservelayout(varargin)

% Redraws the data panel, if necessary

sep_px = 2;
buttonheight_px = 20;

global pupl_globals
userInterface = pupl_globals.UI;
currData = evalin('base', pupl_globals.datavarname);
dataPanel = findobj(userInterface, 'tag', 'activeEyeDataPanel');
activeIdx = getfield(get(userInterface, 'UserData'), 'activeEyeDataIdx');
if ~isempty(get(dataPanel, 'Children'))
    delete(get(dataPanel, 'Children'));
end

fig_pos_px = get(pupl_globals.UI, 'Position');
datapanel_pos_px = getDataPanelPixelPos;
button_top_px = datapanel_pos_px(4) - buttonheight_px;
extraspace_px = -(button_top_px - (buttonheight_px + sep_px)*(numel(currData)+1));
extraspace_rel = extraspace_px / fig_pos_px(4);
datapanel_pos_rel = get(dataPanel, 'Position');
datapanel_pos_rel(2) = datapanel_pos_rel(2) - extraspace_rel;
datapanel_pos_rel(4) = datapanel_pos_rel(4) + extraspace_rel;
if datapanel_pos_rel(2) > 0
    datapanel_pos_rel(2) = 0;
end
if datapanel_pos_rel(4) < 1
    datapanel_pos_rel = [0 0 1 1];
end
ud = get(dataPanel, 'UserData');
ud.OriginalPos = datapanel_pos_rel;
set(dataPanel, 'UserData', ud);
set(dataPanel, 'Position', datapanel_pos_rel);
buttonwidth_px = datapanel_pos_px(3) - sep_px;
%{
if lowestButtonPos < datapanel_pos_px(2)
    % Extend data panel until it hold all the data
    dataPanelRelPos = get(dataPanel, 'Position');
    d = relExtraSpace / 2 * (dataPanelRelPos(4) - dataPanelRelPos(2)); % Relative amount to increase the size by (may be negative);
    % d = 0.5;
    dataPanelRelPos(2) = dataPanelRelPos(2) - d;
    dataPanelRelPos(4) = dataPanelRelPos(4) + d;
    set(dataPanel, 'Position', dataPanelRelPos);
    ud = get(dataPanel, 'UserData');
    ud.OriginalPos(2) = ud.OriginalPos(2) - d;
    ud.OriginalPos(4) = ud.OriginalPos(4) + d;
    set(dataPanel, 'UserData', ud);
    datapanel_pos_px = getDataPanelPixelPos;
    top = datapanel_pos_px(4) - buttonheight_px;
    buttonwidth_px = datapanel_pos_px(3) - sep_px;
else
    
end
%}

datapanel_pos_px = getDataPanelPixelPos;
button_top_px = datapanel_pos_px(4) - buttonheight_px;
for dataidx = 1:numel(currData)
    if activeIdx(dataidx)
        value = 1;
    else
        value = 0;
    end
    currPos = [sep_px, button_top_px - (buttonheight_px+sep_px)*dataidx, buttonwidth_px, buttonheight_px];
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