
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
    'Position', [0.01 0.11 0.98 0.88])
% Regular expression box
if args.regexp
    uicontrol(parent,...
        'Tag', 'regexp',...
        'String', 'regexp',...
        'Style', 'edit',...
        'FontSize', 10,...
        'Units', 'normalized',...
        'Position', [0.01 0.01 0.98 0.08],...
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