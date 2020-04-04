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
axes(p,...
    'Tag', 'hist',...
    'NextPlot', 'add');
p = uipanel(f,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.48 0.08]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'lower',...
    'Callback', @(h,e) updateplot(f),...
    'String', 'lower cutoff',...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.48 0.98]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'upper',...
    'Callback', @(h,e) updateplot(f),...
    'String', 'upper cutoff',...
    'Units', 'normalized',...
    'Position', [0.51 0.01 0.48 0.98]);
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

ud = get(f, 'UserData');

% Get consistent bins
alldata = [ud.data{:}];
n = 4*log2(numel(alldata));
x1 = min(alldata);
x2 = max(alldata);
bins = [x1:(x2-x1)/(n-1):x2 x2+(x2-x1)/(n-1)];

for dataidx = 1:numel(ud.data)
    data = ud.data{dataidx};
    badidx = false(size(data));

    for limType = {'lower' 'upper'}
        currLim = parsedatastr(getlim(f, limType), data);
        if strcmp(limType, 'lower')
            badidx = badidx | data < currLim;
        else
            badidx = badidx | data > currLim;
        end
    end

    histf(data(~badidx), bins, 'EdgeColor', 'w', 'FaceAlpha', 0.5);
    % set(findobj(gca,'Type','line'), 'Marker', 'none');
end
xlabel(ud.args.dataname);
ylabel('Count');
if ~isempty(ud.args.names)
    legend(ud.args.names, 'Interpreter', 'none');
end
title(sprintf('%0.2f%% would be trimmed', 100*nnz(badidx)/numel(badidx)));

end

function currStr = getlim(f, limType)

limType = cellstr(limType);
currStr = get(findobj(f, 'Tag', limType{:}), 'String');

end