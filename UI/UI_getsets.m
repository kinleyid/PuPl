
function AOIsets = UI_getsets(varargin)

options = varargin{1};
try
    setsname = varargin{2};
catch
    setsname = 'set';
end
try
    replacement = varargin{3};
catch
    replacement = true;
end

f = figure(...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'NumberTitle', 'off',...
    'Name', sprintf('Create %ss', setsname),...
    'UserData', struct(...
        'binDescriptions', struct([]),...
        'setsname', setsname));
%% Left panel
createBinsPanel = uipanel(f,...
    'Tag', 'createBinsPanel',...
    'Title', sprintf('Create new %s', setsname),...
    'TitlePosition', 'centertop',...
    'Units', 'Normalized',...
    'Position', [0.01 0.01 0.58 0.98]);
binNamePanel = uipanel(createBinsPanel,...
    'Units', 'Normalized',...
    'Title', sprintf('Name of new %s', setsname),...
    'Units', 'normalized',...
    'Position', [0.01 0.91 0.98 0.08]);
uicontrol(binNamePanel,...
    'Style', 'edit',...
    'String', sprintf('%s 1', setsname),...
    'Tag', 'binName',...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.98])
createBinsSubPanel = uipanel(createBinsPanel,...
    'Units', 'normalized',...
    'Title', 'Members',...
    'Position', [0.01 0.11 0.98 0.78]);
listboxregexp(createBinsSubPanel, options);
createBinsButton = uicontrol(createBinsPanel,...
    'Style', 'pushbutton',...
    'String', sprintf('Create %s', setsname),...
    'Callback', @createbin,...
    'KeyPressFcn', @(h,e)ifkeydo(e,'return',@()createbin(h,e)),...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08]);
set(findobj(createBinsSubPanel, 'Style', 'listbox'),...
    'KeyPressFcn', @(h,e)ifkeydo(e,'return',@()createbin(createBinsButton,e)))
%% Right panel
binControlPanel = uipanel(f,...
    'Tag', 'binControlPanel',...
    'Units', 'Normalized',...
    'Title', sprintf('Current %s', setsname),...
    'TitlePosition', 'centertop',...
    'Position', [0.61 0.01 0.38 0.98]);
uicontrol(binControlPanel,...
    'Style', 'listbox',...
    'Tag', 'binsBox',...
    'Max', inf,...
    'Units', 'normalized',...
    'KeyPressFcn', @(h,e)ifkeydo(e,'delete',@deletebins),...
    'Position', [0.01 0.21 0.98 0.78])
uicontrol(binControlPanel,...
    'Style', 'pushbutton',...
    'String', sprintf('Delete selected %ss', setsname),...
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
if isgraphics(f)
    AOIsets = getfield(get(f, 'UserData'), 'binDescriptions');
    close(f);
else
    AOIsets = [];
end

end
%%
function createbin(h,e)

f = gcbf;
UserData = get(f, 'UserData');
eps = findobj(get(h, 'Parent'), 'Style', 'listbox');
bins = findobj(f, 'Tag', 'binsBox');
priorBinsValue = get(bins, 'Value');
binName = findobj(f, 'Tag', 'binName');
set(bins, 'String', [get(bins, 'String'); cellstr(get(binName, 'String'))]);

epsString = get(eps, 'String');
UserData.binDescriptions = cat(2, UserData.binDescriptions,...
    struct('name', get(binName, 'String'),...
        'members', {epsString(get(eps, 'Value'))}));  

updatename(f, UserData);
% set(binName, 'String', sprintf('New %s', UserData.setsname));
set(bins, 'Value', priorBinsValue);
set(eps, 'Value', []);

uicontrol(findobj(f, 'Tag', 'binName'));

set(f, 'UserData', UserData);

end

function deletebins(varargin)

f = gcbf;
bins = findobj(f, 'Tag', 'binsBox');
UserData = get(f, 'UserData');
UserData.binDescriptions(get(bins, 'Value')) = [];
String = get(bins, 'String');
String(get(bins, 'Value')) = [];
binName = findobj(f, 'Tag', 'binName');
if ~isempty(sscanf(get(binName, 'String'), sprintf('%s %%d', UserData.setsname)))
    updatename(f, UserData);
end
set(bins, 'String', String);
set(bins, 'Value', []);
set(f, 'UserData', UserData);

end

function updatename(f, UserData)

nBins = numel(UserData.binDescriptions);
binName = findobj(f, 'Tag', 'binName');
set(binName, 'String', sprintf('%s %d', UserData.setsname, nBins + 1));

end

function ifkeydo(e, key, fn)

switch e.Key
    case key
        feval(fn);
end

end