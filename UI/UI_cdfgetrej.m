
function threshold = UI_cdfgetrej(data, varargin)

if ~iscell(data)
    data = {data};
end

p = inputParser;
addParameter(p, 'dataname', 'data points');
addParameter(p, 'threshname', 'Threshold');
addParameter(p, 'names', []);
addParameter(p, 'outcomename', 'rejected');
addParameter(p, 'defthresh', 'Select threshold');
addParameter(p, 'lims', []);
addParameter(p, 'func', @ge);
parse(p, varargin{:});

args = p.Results;

f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'NumberTitle', 'off',...
    'Name', 'Rejection threshold',...
    'UserData', struct(...
        'data', {data},...
        'args', {args}));
axes(...
    'Parent', f,...
    'Tag', 'axis',...
    'Units', 'normalized',...
    'Position', [0.11 0.21 0.78 0.68]);
uicontrol('Style', 'edit',...
    'Tag', 'threshold',...
    'String', args.defthresh,...
    'Units', 'normalized',...
    'Callback', @(h,e)plotrejection(f),...
    'Position', [0.01 0.01 0.48 0.08]);
uicontrol('Style', 'pushbutton',...
    'Units', 'normalized',...
    'String', 'Accept',...
    'Callback', @(h,e)uiresume(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @()uiresume(f)),...
    'Position', [0.51 0.01 0.23 0.08]);
uicontrol('Style', 'pushbutton',...
    'Units', 'normalized',...
    'String', 'Cancel',...
    'Callback', @(h,e)delete(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @()delete(f)),...
    'Position', [0.76 0.01 0.23 0.08]);

plotrejection(f)
uiwait(f)
if isgraphics(f)
    threshold = getcurrthresh(f);
    close(f)
else
    threshold = [];
end

end

function plotrejection(f)

axes(findobj(f, 'Tag', 'axis'));
cla('reset');
set(gca, 'Tag', 'axis'); % So we can find it again
hold('on');

ud = get(f, 'UserData');

% Get consistent xlims
alldata = [ud.data{:}];
alldata = alldata(:);
if isempty(ud.args.lims)
    lims = [min(alldata) max(alldata)];
else
    lims = ud.args.lims;
end

for dataidx = 1:numel(ud.data)
    data = ud.data{dataidx};
    data = data(~isnan(data));

    currThreshold = parsedatastr(getcurrthresh(f), data);

    thresholds = linspace(lims(1), lims(2), 1000);   
    ppnViolating = sum(bsxfun(ud.args.func, data(:), thresholds))/numel(data);
    currPpnViolating = nnz(ud.args.func(data, currThreshold))/numel(data);
    p = plot(thresholds, ppnViolating);
    c = get(p, 'Color');
    plot(repmat(currThreshold, 1, 2), [0 1], '--', 'Color', c, 'HandleVisibility', 'off')
    plot(lims, repmat(currPpnViolating, 1, 2), '--', 'Color', c, 'HandleVisibility', 'off')
end

xlim(lims);
ylim([0 1]);
xlabel(ud.args.threshname);
ylabel(sprintf('Proportion of %s above threshold', ud.args.dataname));
nmissing = sum(cellfun(@(x) nnz(ud.args.func(x, currThreshold)), ud.data));
ntotal = sum(cellfun(@numel, ud.data));
title(sprintf('%d %s (%.2f%%) would be %s', nmissing, ud.args.dataname, 100*nmissing/ntotal, ud.args.outcomename));
if ~isempty(ud.args.names)
    legend(ud.args.names, 'Interpreter', 'none');
end

hold('off');

end

function thresh = getcurrthresh(f)

teditbox = findobj(f, 'Tag', 'threshold');
thresh = get(teditbox, 'String');

end