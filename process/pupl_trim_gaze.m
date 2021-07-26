function out = pupl_trim_gaze(EYE, varargin)
% Remove gaze outliers
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
fprintf('Invalid gaze points are:\n');
txt = {};
txt(1:3:10) = {'x' 'x' 'y' 'y'};
txt(2:3:11) = {'<' '>' '<' '>'};
txt(3:3:12) = args.lims;
fprintf('\t%s %s %s\n', txt{:});

end

function lims = sub_getargs(EYE)

x = mergefields(EYE, 'gaze', 'x');
y = mergefields(EYE, 'gaze', 'y');

f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'UserData', struct(...
        'lims', [min(x) max(x) min(y) max(y)],...
        'EYE', EYE,...
        'x', x, 'y', y));
p1 = uipanel(f,...
    'Tag', 'plotpanel',...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.88]);
ax = axes(p1,...
    'Tag', 'middlescatter',...
    'NextPlot', 'add',...
    'Units', 'normalized',...
    'Position', [0.21 0.21 0.78 0.78]);
set(ax, 'xtick', []);
set(ax, 'ytick', []);
bh = axes(p1,...
    'Tag', 'bottomhist',...
    'NextPlot', 'add',...
    'Units', 'normalized',...
    'OuterPosition', [0.21 0.01 0.78 0.20]);
xlabel(pupl_getunits(EYE, 'gaze', 'x'));
set(bh, 'ytick', []);
pos = get(bh, 'Position');
opos = get(bh, 'OuterPosition');
pos([1 3]) = opos([1 3]);
pos(4) = opos(4) - pos(2);
set(bh, 'Position', pos);
lh = axes(p1,...
    'Tag', 'lefthist',...
    'NextPlot', 'add',...
    'Units', 'normalized',...
    'OuterPosition', [0.01 0.21 0.20 0.78]);
set(gca,'view',[90 -90]);
xlabel(pupl_getunits(EYE, 'gaze', 'y'))
set(lh, 'ytick', []);
pos = get(lh, 'Position');
opos = get(lh, 'OuterPosition');
pos([2 4]) = opos([2 4]);
pos(3) = opos(3) - pos(1);
set(lh, 'Position', pos);
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
p_width = 0.15;
txt = {
    'x lower cutoff' 'xLower'
    'x upper cutoff' 'xUpper'
    'y lower cutoff' 'yLower'
    'y upper cutoff' 'yUpper'
};
for txt_idx = 1:size(txt, 1)
    p = uipanel(f,...
        'Units', 'normalized',...
        'Title', txt{txt_idx, 1},...
        'Position', [p_width*(txt_idx-1)+0.01 0.01 p_width-0.02 0.08]);
    UI_adjust(p);
    uicontrol(p,...
        'Style', 'edit',...
        'Tag', txt{txt_idx, 2},...
        'TooltipString', UI_getdatastrtooltip,...
        'Callback', @(h,e) updateplot(f),...
        'Units', 'normalized',...
        'Position', [0.01 0.01 0.98 0.98]);
end
b_width = (1-4*p_width)/2;
uicontrol(f,...
    'String', 'Done',...
    'Units', 'normalized',...
    'Callback', @(h,e) uiresume(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() uiresume(f)),...
    'Position', [4*p_width+0.01 0.01 b_width-0.02 0.08]);
uicontrol(f,...
    'String', 'Cancel',...
    'Units', 'normalized',...
    'Callback', @(h,e) delete(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() delete(f)),...
    'Position', [4*p_width+b_width+0.01 0.01 b_width-0.02 0.08]);
    
createplot(f);

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

function createplot(f)

UserData = get(f, 'UserData');
EYE = UserData.EYE;

badIdx = struct(...
    'x', false(size(UserData.x)),...
    'y', false(size(UserData.y)));

lims = [];
for side = {'x' 'y'}
    for limType = {'Lower' 'Upper'}
        currLim = getlim(f, side, limType);
        if strcmp(limType, 'Lower')
            badIdx.(side{:}) = badIdx.(side{:}) | UserData.(side{:}) < currLim;
        else
            badIdx.(side{:}) = badIdx.(side{:}) | UserData.(side{:}) > currLim;
        end
        lims = [lims currLim];
    end
end

x = UserData.x;
y = UserData.y;

badIdx.both = badIdx.x | badIdx.y;

ax = findobj(f, 'Type', 'axes', 'Tag', 'middlescatter');
axes(ax);
cla;
set(ax, 'Tag', 'middlescatter'); % So we can find it again

s1 = scatter(x, y, 0.5, 'k');
try
    alpha(s1, 0.1);
end
s2 = scatter(nan(size(x)), nan(size(y)), 0.5, 'r');
try
    alpha(s2, 0.1);
end
xlimits = xlim;
ylimits = ylim;
set(ax, 'xtick', []);
set(ax, 'ytick', []);

UserData.s1 = s1;
UserData.s2 = s2;

p = [];

p(1) = plot(lims([1 1]), ylimits, 'r--');
p(2) = plot(lims([2 2]), ylimits, 'r--');
p(3) = plot(xlimits, lims([3 3]), 'r--');
p(4) = plot(xlimits, lims([4 4]), 'r--');

UserData.p1 = p;

p = [];
axes(findobj(f, 'Tag', 'bottomhist'));
cla
hist(x, xlimits(2) - xlimits(1))
pre_y = ylim;
p(1) = plot(lims([1 1]), pre_y, 'r--');
p(2) = plot(lims([2 2]), pre_y, 'r--');
xlim(xlimits);
ylim(pre_y);
axes(findobj(f, 'Tag', 'lefthist'));
cla
hist(y, ylimits(2) - ylimits(1))
pre_y = ylim;
p(3) = plot(lims([3 3]), pre_y, 'r--');
p(4) = plot(lims([4 4]), pre_y, 'r--');
xlim(ylimits);
ylim(pre_y);
UserData.p2 = p;
set(findobj(f, 'Tag', 'reporttext'), 'String', sprintf('%0.2f%% trimmed', 100*nnz(badIdx.both)/numel(badIdx.both)));

set(f, 'UserData', UserData);

end

function updateplot(f)

UserData = get(f, 'UserData');

badIdx = struct(...
    'x', false(size(UserData.x)),...
    'y', false(size(UserData.y)));

ii = 0;
for side = {'x' 'y'}
    for limType = {'Lower' 'Upper'}
        ii = ii + 1;
        currLim = getlim(f, side, limType);
        currData = sprintf('%sData', upper(side{:}));
        set(UserData.p1(ii), currData, currLim([1 1]));
        set(UserData.p2(ii), 'XData', currLim([1 1]));
        if strcmp(limType, 'Lower')
            badIdx.(side{:}) = badIdx.(side{:}) | UserData.(side{:}) < currLim;
        else
            badIdx.(side{:}) = badIdx.(side{:}) | UserData.(side{:}) > currLim;
        end
    end
end
badIdx.both = badIdx.x | badIdx.y;

axes(findobj(f, 'Type', 'axes', 'Tag', 'middlescatter'));
y_pre = ylim;
x_pre = xlim;

% Re-scatter good data
xd = UserData.x;
yd = UserData.y;
xd(badIdx.both) = nan;
yd(badIdx.both) = nan;
set(UserData.s1, 'XData', xd);
set(UserData.s1, 'YData', yd);
% And bad data
xd = UserData.x;
yd = UserData.y;
xd(~badIdx.both) = nan;
yd(~badIdx.both) = nan;
set(UserData.s2, 'XData', xd);
set(UserData.s2, 'YData', yd);

ylim(y_pre);
xlim(x_pre);

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

% Convert string to numerical limits

lims = [];
lims.x = [
    parsedatastr(args.lims{1}, EYE.gaze.x)
    parsedatastr(args.lims{2}, EYE.gaze.x)
];
lims.y = [
    parsedatastr(args.lims{3}, EYE.gaze.y)
    parsedatastr(args.lims{4}, EYE.gaze.y)
];

badidx = false(1, EYE.ndata);
for field = reshape(fieldnames(EYE.gaze), 1, [])
    badidx = badidx | ...
        EYE.gaze.(field{:}) < lims.(field{:})(1) | ...
        EYE.gaze.(field{:}) > lims.(field{:})(2);
end

EYE = pupl_proc(EYE, @(x) badidx2nan(x, badidx), 'all');
fprintf('%0.2f%% data removed\n', 100*nnz(badidx)/EYE.ndata)

end

function x = badidx2nan(x, badidx)

x(badidx) = nan;

end
