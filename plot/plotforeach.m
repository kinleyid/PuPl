
function plotforeach(EYE, plotfunc, varargin)

f = figure(...
    'NumberTitle', 'off',...
    'UserData', struct(...
        'dataidx', 0,...
        'data', EYE,...
        'plotfunc', plotfunc,...
        'varargin', {varargin}));
a = axes(f,...
    'Tag', 'ax',...
    'Units', 'normalized',...
    'OuterPosition', [0.01 0.11 0.98 0.88]);
p = uipanel(f,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08]);
uicontrol(p,...
    'String', 'Quit',...
    'Units', 'normalized',...
    'Callback', @(h,e) delete(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() delete(f)),...
    'Position', [0.01 0.01 0.18 0.98]);
if numel(EYE) > 1
    enablestate = 'on';
else
    enablestate = 'off';
end
uicontrol(p,...
    'String', '<< Previous recording <<',...
    'Enable', enablestate,...
    'Units', 'normalized',...
    'Callback', @(h,e) datainc(f, -1),...
    'KeyPressFcn', @(h,e) enterdo(e, @() datainc(f, -1)),...
    'Position', [0.21 0.01 0.38 0.98]);
uicontrol(p,...
    'String', '>> Next recording >>',...
    'Enable', enablestate,...
    'Units', 'normalized',...
    'Callback', @(h,e) datainc(f, 1),...
    'KeyPressFcn', @(h,e) enterdo(e, @() datainc(f, 1)),...
    'Position', [0.61 0.01 0.38 0.98]);

datainc(f, 1);

axes(a);

end

function datainc(f, n)

ud = get(f, 'UserData');
ii = ud.dataidx + n;
data = ud.data;
if ii > numel(data)
    ii = 1;
elseif ii < 1
    ii = numel(data);    
end
ud.dataidx = ii;

set(f, 'UserData', ud);
set(f, 'Name', data(ii).name);
a = findobj(f, 'Tag', 'ax');
cla(a);
ud.plotfunc(a, data(ii), ud.varargin{:});
title(data(ii).name, 'Interpreter', 'none');

end