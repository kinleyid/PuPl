function [idx, names] = listdlgregexp(varargin)

p = inputParser;
addParameter(p, 'ListString', []);
addParameter(p, 'PromptString', []);
addParameter(p, 'ListSize', []);
addParameter(p, 'SelectionMode', []);
parse(p, varargin{:});

if isempty(p.Results.ListString)
    return
else
    listString = p.Results.ListString;
end
if isempty(p.Results.PromptString)
    [prompt, figTitle] = deal('');
else
    [prompt, figTitle] = deal(p.Results.PromptString);
end

f = figure(...
    'Name', figTitle,...
    'NumberTitle', 'off',...
    'MenuBar', 'none');

uicontrol(f,...
    'Style', 'text',...
    'String', prompt,...
    'Units', 'normalized',...
    'Position', [0.01 0.91 0.98 0.08]);

panel = uipanel(f,...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.78]);
listboxregexp(panel, listString);
set(findobj(f, 'Style', 'listbox'), 'KeyPressFcn', @(h, e) enterdo(e, @() uiresume(f)));
uicontrol(f,...
    'Style', 'pushbutton',...
    'String', 'Done',...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08],...
    'KeyPressFcn', @(h, e) enterdo(e, @() uiresume(f)),...
    'Callback', @(h, e) uiresume(f));

uicontrol(findobj(f, 'Style', 'listbox'))

uiwait(f);
if isgraphics(f)
    listBox = findobj(panel, 'Style', 'listbox');
    idx = get(listBox, 'Value');
    names = listString(idx);
    close(f);
else
    idx = [];
end

end