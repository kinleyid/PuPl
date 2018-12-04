
function binDescriptions = UI_getbindescriptions(EYE)

f = figure(...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'NumberTitle', 'off',...
    'Name', 'Create trial sets',...
    'UserData', struct('binDescriptions', []));
%% Left panel
createBinsPanel = uipanel(f,...
    'Tag', 'createBinsPanel',...
    'Units', 'Normalized',...
    'Position', [0.01 0.01 0.58 0.98]);
uicontrol(createBinsPanel,...
    'Style', 'text',...
    'String', 'Name of new trial set:',...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.01 0.91 0.48 0.08])
uicontrol(createBinsPanel,...
    'Style', 'edit',...
    'String', 'New trial set',...
    'Tag', 'binName',...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.51 0.91 0.48 0.08])
createBinsSubPanel = uipanel(createBinsPanel,...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.78]);
listboxregexp(createBinsSubPanel, unique(mergefields(EYE, 'epoch', 'name')));
uicontrol(createBinsPanel,...
    'Style', 'pushbutton',...
    'String', 'Create trial set',...
    'Callback', @createbin,...
    'KeyPressFcn', @(h,e)ifkeydo(e,'return',@()createbin(h,e)),...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08])
%% Right panel
binControlPanel = uipanel(f,...
    'Tag', 'binControlPanel',...
    'Units', 'Normalized',...
    'Position', [0.61 0.01 0.38 0.98]);
uicontrol(binControlPanel,...
    'Style', 'text',...
    'String', 'Current trial sets:',...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.01 0.91 0.98 0.08])
uicontrol(binControlPanel,...
    'Style', 'listbox',...
    'Tag', 'binsBox',...
    'Max', inf,...
    'Units', 'normalized',...
    'Position', [0.01 0.21 0.98 0.68])
uicontrol(binControlPanel,...
    'Style', 'pushbutton',...
    'String', 'Delete selected trial sets',...
    'Callback', @deletebins,...
    'KeyPressFcn', @(h,e)ifkeydo(e,'return',@deletebins),...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.08])
uicontrol(binControlPanel,...
    'Style', 'pushbutton',...
    'String', 'Done',...
    'Callback', @(h,e)uiresume(f),...
    'KeyPressFcn', @(h,e)ifkeydo(e,'return',@()uiresume(f)),...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08])
%%
uicontrol(findobj(f, 'Tag', 'binName'));
uiwait(f);
if isvalid(f)
    binDescriptions = f.UserData.binDescriptions;
    close(f);
else
    binDescriptions = [];
end

end

function createbin(h,e)

f = gcbf;
eps = findobj(h.Parent, 'Style', 'listbox');
bins = findobj(f, 'Tag', 'binsBox');
priorBinsValue = bins.Value;
binName = getcomponentbytag(f, 'createBinsPanel', 'binName');
bins.String = [bins.String; cellstr(binName.String)];

f.UserData.binDescriptions = cat(2, f.UserData.binDescriptions,...
    struct('name', binName.String,...
        'epochs', {eps.String(eps.Value)}));  

binName.String = sprintf('New bin');
bins.Value = priorBinsValue;
eps.Value = [];

uicontrol(findobj(f, 'Tag', 'binName'));

end

function deletebins(varargin)

f = gcbf;
bins = getcomponentbytag(f, 'binControlPanel', 'binsBox');
f.UserData.binDescriptions(bins.Value) = [];
bins.String(bins.Value) = [];
bins.Value = [];

end

function ifkeydo(e, key, do)

switch e.Key
    case key
        do();
end

end