function preservelayout(varargin)

sep = 2;
buttonHeight = 20;

global userInterface eyeData

currData = eyeData;
currPanel = findobj(userInterface, 'tag', 'activeEyeDataPanel');
activeIdx = getfield(get(userInterface, 'UserData'), 'activeEyeDataIdx');
if ~isempty(get(currPanel, 'Children'))
    delete(get(currPanel, 'Children'));
end
activeIdx(numel(activeIdx)+1:numel(currData)) = true;
bgPos = get(userInterface, 'position') .* get(currPanel, 'position');
top = bgPos(4) - buttonHeight;
buttonWidth = bgPos(3) - sep;
for i = 1:numel(currData)
    if activeIdx(i)
        value = 1;
    else
        value = 0;
    end
    uicontrol(currPanel,...
        'Style', 'checkbox',...
        'Position', [sep, top - (buttonHeight+sep)*i, buttonWidth, buttonHeight],...
        'String', currData(i).name,...
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
