
function sel = pupl_UI_select(EYE, varargin)

% Select events

args = pupl_args2struct(varargin, {
    'prompt' 'Select events'
    'type' 'event'
});

switch args.type
    case 'event'
        all_events = mergefields(EYE, 'event');
    case 'epoch'
        all_events = [];
        for dataidx = 1:numel(EYE)
            all_events = [all_events pupl_epoch_get(EYE(dataidx), {EYE(dataidx).epoch}, '_tl')];
        end
end
% Get data for UI table
[data, colnames] = pupl_event_toUITcell(all_events);

if strcmp(args.type, 'epoch')
    colnames{strcmp(colnames, 'name')} = 'timelocking event';
    colnames = [{'epoch'} colnames];
    ep_names = mergefields(EYE, 'epoch', 'name');
    data = [ep_names(:) data];
end

if numel(EYE) > 1
    % Add columns for recording
    colnames = [{'recording'} colnames];
    new_col = [];
    for dataidx = 1:numel(EYE)
        new_col = [new_col; repmat({EYE(dataidx).name}, numel(EYE(dataidx).(args.type)), 1)];
    end
    data = [new_col data];
end

colnames = ['selected' colnames];
data = [num2cell(false(numel(all_events), 1)) data];

% Main figure
f = figure(...
    'UserData', struct(...
        'events', all_events,...
        'n', 0,...
        'checkboxes', false(numel(all_events), 3),...
        'selector', {{'' '' ''}}),...
    'Name', 'Event filter',...
    'NumberTitle', 'off',...
    'Menu', 'none');
% Prompt
uicontrol(f,...
    'Style', 'text',...
    'String', args.prompt,...
    'Units', 'normalized',...
    'Position', [0.01 0.91 0.98 0.08]);
uicontrol(f,...
    'Style', 'text',...
    'Tag', 'n.sel',...
    'String', sprintf('0/%d selected', numel(all_events)),...
    'Units', 'normalized',...
    'Position', [0.01 0.86 0.98 0.08]);
% UI table in which events are displayed
uitable(f,...
    'Data', data,...
    'ColumnName', colnames,...
    'Tag', 'uit',...
    'ColumnEditable', false(1, numel(colnames)),...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.78]);
p1 = uipanel(f,...
    'Title', 'Select by:',...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.23 0.08]);
uicontrol(p1,...
    'Style', 'popupmenu',...
    'Tag', 'selector-menu',...
    'String', {'Checkbox' 'Regular expression' 'Event variable'},...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.98],...
    'Callback', @(h,e) update_selector(f));
p2 = uipanel(f,...
    'Title', 'Filter',...
    'Tag', 'filter-panel',...
    'Units', 'normalized',...
    'Position', [0.26 0.01 0.33 0.08]);
uicontrol(p2,...
    'Style', 'edit',...
    'Tag', 'filter-box',...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.98],...
    'Callback', @(h,e) update_selection(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() update_selection(f)));
uicontrol(f,...
    'String', 'Done',...
    'Units', 'normalized',...
    'Position', [0.61 0.01 0.18 0.08],...
    'Callback', @(h,e) uiresume(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() uiresume(f)));
uicontrol(f,...
    'String', 'Cancel',...
    'Units', 'normalized',...
    'Position', [0.81 0.01 0.18 0.08],...
    'Callback', @(h,e) delete(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() delete(f)));

update_selector(f);

uiwait(f);
if isgraphics(f)
    ud = get(f, 'UserData');
    selmen = findobj(f, 'Tag', 'selector-menu');
    seltypeopts = get(selmen, 'String');
    seltype = get(selmen, 'Value');
    switch seltypeopts{seltype}
        case 'Checkbox'
            % Get checkbox values
            uit = findobj(f, 'Tag', 'uit');
            data = get(uit, 'Data');
            colnames = get(uit, 'ColumnName');
            sel_col_idx = strcmp(colnames, 'selected');
            idx = logical([data{:, sel_col_idx}]);
            sel = {ud.n ud.events(idx).name};
        otherwise
            filt_box = findobj(f, 'Tag', 'filter-box');
            sel = {ud.n get(filt_box, 'String')};
    end
    close(f);
else
    sel = [];
end

end

function update_selector(f)

ud = get(f, 'UserData');
uit = findobj(f, 'Tag', 'uit');
data = get(uit, 'Data');
colnames = get(uit, 'ColumnName');
selmen = findobj(f, 'Tag', 'selector-menu');
str = get(selmen, 'String');
val = get(selmen, 'Value');
% Assume columns are not editable
col_ed = false(size(colnames));
sel_col_idx = strcmp(colnames, 'selected');
filt_panel = findobj(f, 'Tag', 'filter-panel');
filt_box = findobj(f, 'Tag', 'filter-box');
set(filt_panel, 'Visible', 'on');

ud.checkboxes(:, ud.n + 1) = [data{:, sel_col_idx}];
ud.selector{ud.n + 1} = get(filt_box, 'String');

switch str{val}
    case 'Checkbox'
        col_ed(sel_col_idx) = true;
        set(filt_panel, 'Title', '');
        set(filt_panel, 'Visible', 'off');
        ud.n = 0;
    case 'Regular expression'
        set(filt_panel, 'Title', 'Regular expression');
        set(filt_box, 'TooltipString', pupl_gettooltip('regexp:edit'));
        ud.n = 1;
    case 'Event variable'
        set(filt_panel, 'Title', 'Event variable filter');
        set(filt_box, 'TooltipString', pupl_gettooltip('eventvar:edit'));
        ud.n = 2;
end

set(filt_box, 'String', ud.selector{ud.n + 1});
data(:, sel_col_idx) = num2cell(ud.checkboxes(:, ud.n + 1));

set(uit, 'ColumnEditable', col_ed(:)')
set(uit, 'Data', data);
set(f, 'UserData', ud);

end

function update_selection(f)

ud = get(f, 'UserData');
uit = findobj(f, 'Tag', 'uit');
data = get(uit, 'Data');
colnames = get(uit, 'ColumnName');
filt_box = findobj(f, 'Tag', 'filter-box');
filt = get(filt_box, 'String');
sel_idx = pupl_event_sel(ud.events, {ud.n filt});
sel_col_idx = strcmp(colnames, 'selected');
data(:, sel_col_idx) = num2cell(sel_idx);
set(uit, 'Data', data);

n_sel = findobj(f, 'Tag', 'n.sel');
set(n_sel, 'String', sprintf('%d/%d selected', nnz(sel_idx), numel(ud.events)));

end