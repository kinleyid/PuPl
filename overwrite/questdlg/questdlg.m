
function a = questdlg(varargin)

q = '';
title = '';
button_txt = {'Yes' 'No' 'Cancel' 'Yes'};
if nargin > 0
    q = varargin{1};
end
if nargin > 1
    title = varargin{2};
end
if nargin > 2
    button_txt = varargin(3:end);
end

def_fp = get(0, 'defaultFigurePosition');
scr_sz = get(0, 'screenSize');
def_fp([1 3]) = def_fp([1 3]) / scr_sz(3);
def_fp([2 4]) = def_fp([2 4]) / scr_sz(4);
curr_fp = [def_fp(1:2) def_fp(3) def_fp(4)/3];

% Center on the screen
curr_fp(1:2) = (1 - curr_fp(3:4)) / 2;

f = figure(...
    'NumberTitle', 'off',...
    'Name', title,...
    'MenuBar', 'none',...
    'Units', 'normalized',...
    'Position', curr_fp);

uicontrol(...
    'Parent', f,...
    'Style', 'text',...
    'String', q,...
    'FontSize', 10,...
    'Units', 'normalized',...
    'Position', [0.01 0.51 0.98 0.38],...
    'UserData', [])

% Check for default button
def_button = find(strcmp(button_txt(1:end-1), button_txt{end}), 1);
if any(def_button)
    button_txt(end) = [];
end

n_buttons = numel(button_txt);
button_width = 1 / n_buttons - 0.02;
button_objs = cell(1, n_buttons); % Contained for graphics objects
for bidx = 1:n_buttons
    curr_x_pos = (bidx - 1) / n_buttons + 0.01;
    button_objs{bidx} = uicontrol(...
        'Parent', f,...
        'String', sprintf(button_txt{bidx}),...
        'Units', 'normalized',...
        'Position', [curr_x_pos 0.21 button_width 0.28],...
        'Callback', @(h, e) sel(h, f),...
        'KeyPressFcn', @(h, e) enterdo(e, @() sel(h, f)));
end

if any(def_button)
    uicontrol(button_objs{def_button});
end

uiwait(f);

if isgraphics(f)
    a = get(f, 'UserData');
    delete(f);
else
    a = '';
end

end

function sel(h, f)

set(f, 'UserData', get(h, 'String'));
uiresume(f);

end