function idx = listdlgregexp(varargin)

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
    prompt = '';
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
uicontrol(f,...
    'Style', 'pushbutton',...
    'String', 'Done',...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08],...
    'KeyPressFcn', @enterkeyuiresume,...
    'Callback', @buttonpressresume);

uiwait(f);
if isvalid(f)
    listBox = findobj(panel, 'Style', 'listbox');
    idx = listBox.Value;
    close(f);
else
    idx = [];
end

end

function buttonpressresume(h,e)

uiresume(gcbf)

end

function enterkeyuiresume(h,e)

if strcmp(e.Key, 'return')
    uiresume(gcbf)
end

end