
function listboxregexp(parent, contents, varargin)

%   Inputs
% parent--graphics object
% contents--cell array of char

args = pupl_args2struct(varargin, {
    'SelectionMode' 'multiple'
    'regexp' true
});
switch args.SelectionMode
    case 'single'
        maxsel = 1;
    case 'multiple'
        maxsel = inf;
end

contents = cellstr(contents);

% List box
uicontrol(parent,...
    'UserData', args,...
    'Style', 'listbox',...
    'Max', maxsel,...
    'String', contents,...
    'Units', 'normalized',...
    'Position', [0.01 0.16 0.98 0.83])
% Regular expression box
if args.regexp
    p = uipanel(parent,...
        'Title', 'regexp',...
        'Units', 'normalized',...
        'Position', [0.01 0.01 0.98 0.13]);
    UI_adjust(p);
    uicontrol(p,...
        'Tag', 'regexp',...
        'String', 'regexp',...
        'TooltipString', pupl_gettooltip('regexp:edit'),...
        'Style', 'edit',...
        'Units', 'normalized',...
        'Position', [0.01 0.01 0.98 0.98],...
        'Callback', @(h,e) selectbyregexp(h),...
        'KeyPressFcn', @(h,e) enterdo(e, @() selectbyregexp(h)))
end

end

function selectbyregexp(src)

listBox = findobj(get(src, 'Parent'), 'Style', 'listbox');
value = find(~cellfun(@isempty, regexp(get(listBox, 'String'), get(src, 'String'))));
args = get(listBox, 'UserData');
if strcmp(args.SelectionMode, 'single')
    if isempty(value)
        value = 1;
    else
        value = value(1);
    end
end
set(listBox, 'Value', value);

end