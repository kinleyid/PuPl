function lims = UI_histgetrej(data, varargin)
% Data will be a cell array

if ~iscell(data)
    data = {data};
end

args = pupl_args2struct(varargin, {
    'dataname' 'data'
    'names' []
});

f = figure(...
    'ToolBar', 'none',...
    'UserData', struct(...
        'data', {data},...
        'args', {args}));
p = uipanel(f,...
    'Tag', 'plotpanel',...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.88]);
axes(...
    'Parent', p,...
    'Tag', 'hist',...
    'NextPlot', 'add');
p = uipanel(f,...
    'Units', 'normalized',...
    'Title', 'Lower cutoff',...
    'Position', [0.01 0.01 0.23 0.08]);
UI_adjust(p);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'lower',...
    'TooltipString', pupl_gettooltip('datastr'),...
    'Callback', @(h,e) updateplot(f),...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.98]);
p = uipanel(f,...
    'Units', 'normalized',...
    'Title', 'Upper cutoff',...
    'Position', [0.25 0.01 0.23 0.08]);
UI_adjust(p);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'upper',...
    'TooltipString', pupl_gettooltip('datastr'),...
    'Callback', @(h,e) updateplot(f),...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.98]);
p = uipanel(f,...
    'Units', 'normalized',...
    'Position', [0.51 0.01 0.48 0.08]);
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
    lims{1} = getlim(f, 'lower');
    lims{2} = getlim(f, 'upper');
    close(f);
else
    lims = [];
end

end

function updateplot(f)

axes(findobj(f, 'Type', 'axes', 'Tag', 'hist'));
cla;
set(gca, 'Tag', 'hist'); % So we can find it again
ud = get(f, 'UserData');

% Get consistent bins
alldata = [ud.data{:}];
n = 4*log2(numel(alldata));
x1 = min(alldata);
x2 = max(alldata);
bins = [x1:(x2-x1)/(n-1):x2 x2+(x2-x1)/(n-1)];
if any(isnan(bins)) % All data is missing
    bins = 10; % Same value as histf. Shouldn't matter anyway, as nothing will be displayed.
end
% Generate histograms
lims = {}; % <- keep track of cutoffs
for dataidx = 1:numel(ud.data)
    data = ud.data{dataidx};
    badidx = false(size(data));
    
    lims{dataidx} = [];
    for limType = {'lower' 'upper'}
        currLim = parsedatastr(getlim(f, limType), data);
        if strcmp(limType, 'lower')
            badidx = badidx | data <= currLim;
        else
            badidx = badidx | data >= currLim;
        end
        lims{dataidx} = [lims{dataidx} currLim];
    end
    hist(data(~badidx), bins);
    % Keep track of the order in which the hists were added
    patches = findobj(gca, 'Type', 'patch');
    for patch_idx = 1:numel(patches)
        if isempty(get(patches(patch_idx), 'UserData'))
            set(patches(patch_idx), 'UserData', dataidx);
        end
    end
end
% Record prior xlims and ylims
pre_xlim = xlim;
pre_ylim = ylim;
% Set alpha and colours
patches = findobj(gca, 'Type', 'patch');
set(patches, 'EdgeColor', 'w');
try
    alpha(patches, 0.4);
end
npatches = numel(patches);
colours = lines(npatches);
for patch_idx = 1:npatches
    data_idx = get(patches(patch_idx), 'UserData');
    set(patches(patch_idx), 'FaceColor', colours(data_idx, :));
    % Plot cutoffs
    for cutoff_idx = 1:2
        p = plot(lims{data_idx}([cutoff_idx cutoff_idx]), [0 pre_ylim(2)/2], '--');
        set(p, 'Color', colours(data_idx, :));
    end
end
% Restore x lims and y lims, in case they were changed by line plots
xlim(pre_xlim);
ylim(pre_ylim);
% Get rid of little starts along the x axis
set(findobj(gca, 'Type', 'line'), 'Marker', 'none');
% Set labels
xlabel(ud.args.dataname);
ylabel('Count');
if ~isempty(ud.args.names)
    legend(patches, ud.args.names, 'Interpreter', 'none');
end
title(sprintf('%0.2f%% would be trimmed', 100*nnz(badidx)/numel(badidx)));

end

function currStr = getlim(f, limType)

limType = cellstr(limType);
currStr = get(findobj(f, 'Tag', limType{:}), 'String');

end