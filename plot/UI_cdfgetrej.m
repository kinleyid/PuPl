
function threshold = UI_cdfgetrej(data, varargin)

p = inputParser;
addParameter(p, 'dataname', 'data');
addParameter(p, 'threshname', 'Threshold');
addParameter(p, 'lims', [min(data) max(data)]);
parse(p, varargin{:});

dataname = p.Results.dataname;
threshname = p.Results.threshname;
lims = p.Results.lims;    
f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'NumberTitle', 'off',...
    'Name', 'Rejection threshold',...
    'UserData', struct(...
        'data', data,...
        'lims', lims));
axes(f,...
    'Tag', 'axis',...
    'Units', 'normalized',...
    'Position', [0.11 0.21 0.78 0.68]);
uicontrol('Style', 'edit',...
    'Tag', 'threshold',...
    'String', 'Select rejection threshold',...
    'Units', 'normalized',...
    'Callback', @(h,e)plotrejection(f, dataname, threshname),...
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

plotrejection(f, dataname, threshname)
uiwait(f)
if isgraphics(f)
    threshold = getcurrthresh(f);
    close(f)
else
    threshold = [];
end

end

function plotrejection(f, dataname, threshname)

UserData = get(f, 'UserData');
data = UserData.data(~isnan(UserData.data));
lims = UserData.lims;

currThreshold = parsedatastr(getcurrthresh(f), data);

thresholds = linspace(lims(1), lims(2), 1000);   
ppnViolating = sum(bsxfun(@ge, data', thresholds))/numel(data);
currPpnViolating = nnz(data >= currThreshold)/numel(data);
ax = findobj(f, 'Tag', 'axis');
axes(ax); cla; hold on
plot(thresholds, ppnViolating, 'k');
plot(repmat(currThreshold, 1, 2), [0 1], '--k')
plot(lims, repmat(currPpnViolating, 1, 2), '--k')
xlim(lims);
ylim([0 1]);
xlabel(threshname);
ylabel(sprintf('Proportion of %s violating threshold', dataname));
title(sprintf('%d %s (%.2f%%) would be rejected', nnz(data >= currThreshold), dataname, 100*currPpnViolating));

end

function thresh = getcurrthresh(f)

teditbox = findobj(f, 'Tag', 'threshold');
ud = get(f, 'UserData');
thresh = get(teditbox, 'String');

end