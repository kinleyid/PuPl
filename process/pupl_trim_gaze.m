function out = pupl_trim_gaze(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_trim_gaze(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'lims' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});
if isempty(args.lims)
    args.lims = sub_getargs(EYE);
    if isempty(args.lims)
        return
    end
end

outargs = args;

end

function lims = sub_getargs(EYE)

x = mergefields(EYE, 'gaze', 'x');
y = mergefields(EYE, 'gaze', 'y');

f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'UserData', struct(...
        'lims', [min(x) max(x) min(y) max(y)],...
        'x', x,...
        'y', y));
p1 = uipanel(f,...
    'Tag', 'plotpanel',...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.88]);
ax = axes(p1,...
    'Tag', 'middlescatter',...
    'NextPlot', 'add',...
    'Units', 'normalized',...
    'Position', [0.21 0.21 0.78 0.78]);
axes(p1,...
    'Tag', 'bottomhist',...
    'NextPlot', 'add',...
    'Units', 'normalized',...
    'Position', [0.21 0.06 0.78 0.13]);
axes(p1,...
    'Tag', 'lefthist',...
    'NextPlot', 'add',...
    'Units', 'normalized',...
    'Position', [0.06 0.21 0.13 0.78]);
uicontrol(p1,...
    'Style', 'text',...
    'FontSize', 10,...
    'Tag', 'reporttext',...
    'String', '0%% trimmed',...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.18 0.13]);
axes(ax);
scatter(x, y, 5, 'k', 'filled');
xlimits = xlim;
ylimits = ylim;
UserData = get(f, 'UserData');
UserData.lims = [xlimits ylimits];
set(f, 'UserData', UserData);
p = uipanel(f,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.73 0.08]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'xLower',...
    'Callback', @(h,e) updateplot,...
    'String', 'x lower cutoff',...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.23 0.98]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'xUpper',...
    'Callback', @(h,e) updateplot,...
    'String', 'x upper cutoff',...
    'Units', 'normalized',...
    'Position', [0.26 0.01 0.23 0.98]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'yLower',...
    'Callback', @(h,e) updateplot,...
    'String', 'y lower cutoff',...
    'Units', 'normalized',...
    'Position', [0.51 0.01 0.23 0.98]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'yUpper',...
    'Callback', @(h,e) updateplot,...
    'String', 'y upper cutoff',...
    'Units', 'normalized',...
    'Position', [0.76 0.01 0.23 0.98]);
p = uipanel(f,...
    'Units', 'normalized',...
    'Position', [0.76 0.01 0.23 0.08]);
uicontrol(p,...
    'String', 'Done',...
    'Units', 'normalized',...
    'Callback', @(h,e) uiresume(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() uiresume(f)),...
    'Position', [0.01 0.01 0.48 0.98]);
uicontrol(p,...
    'String', 'Cancel',...
    'Units', 'normalized',...
    'Callback', @(h,e) delete(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() delete(f)),...
    'Position', [0.51 0.01 0.48 0.98]);
    
updateplot(f);

uiwait(f);

if isgraphics(f)
    [~, lims{1}] = getlim(f, 'x', 'Lower');
    [~, lims{2}] = getlim(f, 'x', 'Upper');
    [~, lims{3}] = getlim(f, 'y', 'Lower');
    [~, lims{4}] = getlim(f, 'y', 'Upper');
    close(f);
else
    lims = [];
end

end

function updateplot(varargin)

if ~isempty(varargin)
    f = varargin{cellfun(@isgraphics, varargin)};
else
    f = gcbf;
end

UserData = get(f, 'UserData');

badIdx = struct(...
    'x', false(size(UserData.x)),...
    'y', false(size(UserData.y)));

for side = {'x' 'y'}
    for limType = {'Lower' 'Upper'}
        currLim = getlim(f, side, limType);
        if strcmp(limType, 'Lower')
            badIdx.(side{:}) = badIdx.(side{:}) | UserData.(side{:}) < currLim;
        else
            badIdx.(side{:}) = badIdx.(side{:}) | UserData.(side{:}) > currLim;
        end
    end
end

x = UserData.x;
y = UserData.y;

set(f, 'UserData', UserData);

badIdx.both = badIdx.x | badIdx.y;

ax = findobj(f, 'Type', 'axes', 'Tag', 'middlescatter');
axes(ax);
cla;
s = scatter(x(~badIdx.both), y(~badIdx.both), 5, 'k', 'filled');
try
    alpha(s, 0.1);
end
s = scatter(x(badIdx.both), y(badIdx.both), 5, 'r', 'filled');
try
    alpha(s, 0.1);
end
xlimits = xlim;
ylimits = ylim;
set(ax, 'xtick', []);
set(ax, 'ytick', []);
axes(findobj(f, 'Tag', 'bottomhist'));
cla
hist(x, xlimits(2) - xlimits(1))
xlim(xlimits);
set(gca, 'ytick', []);
axes(findobj(f, 'Tag', 'lefthist'));
cla
hist(y, ylimits(2) - ylimits(1))
xlim(ylimits)
set(gca, 'ytick', []);
set(gca,'view',[90 -90])

set(findobj(f, 'Tag', 'reporttext'), 'String', sprintf('%0.2f%% trimmed', 100*nnz(badIdx.both)/numel(badIdx.both)));

end

function [currLim, currStr] = getlim(f, side, limType)

UserData = get(f, 'UserData');
side = cellstr(side);
limType = cellstr(limType);
currStr = get(findobj(f, 'Tag', [side{:} limType{:}]), 'String');
currLim = parsedatastr(currStr, UserData.(side{:}));

end

function EYE = sub_trim_gaze(EYE, varargin)

args = parseargs(varargin{:});

lims = args.lims;

% Convert string to numerical limits

fprintf('Trimming extreme gaze values...\n')

numlims = [
    parsedatastr(lims{1}, EYE.gaze.x)
    parsedatastr(lims{2}, EYE.gaze.x)
    parsedatastr(lims{3}, EYE.gaze.y)
    parsedatastr(lims{4}, EYE.gaze.y)
];
fprintf('\t%s: trimming points where:\n', EYE.name)
fprintf('\t\t\tx < %0.1f\n', numlims(1))
fprintf('\t\t\tx > %0.1f\n', numlims(2))
fprintf('\t\t\ty < %0.1f\n', numlims(3))
fprintf('\t\t\ty > %0.1f\n', numlims(4))
badidx = EYE.gaze.x < numlims(1) |...
    EYE.gaze.x > numlims(2) |...
    EYE.gaze.y < numlims(3) |...
    EYE.gaze.y > numlims(4);

EYE = pupl_proc(EYE, @(x) badidx2nan(x, badidx), 'all');
fprintf('\t\t%0.2f%% of data removed\n', 100*nnz(badidx)/EYE.ndata)

end

function x = badidx2nan(x, badidx)

x(badidx) = nan;

end
