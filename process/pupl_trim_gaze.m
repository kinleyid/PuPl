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
    uicontrol(p,...
        'Style', 'edit',...
        'Tag', txt{txt_idx, 2},...
        'TooltipString', UI_getdatastrtooltip,...
        'Callback', @(h,e) updateplot,...
        'String', txt{txt_idx, 1},...
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
set(ax, 'Tag', 'middlescatter'); % So we can find it again

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
