% Salvucci, D. D., & Goldberg, J. H. (2000, November). Identifying
% fixations and saccades in eye-tracking protocols. In Proceedings of the
% 2000 symposium on Eye tracking research & applications (pp. 71-78). ACM.

function EYE = velocitythresholdsaccadeID(EYE, varargin)

p = inputParser;
addParameter(p, 'threshold', []);
parse(p, varargin{:});
callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

if isempty(p.Results.threshold)
    threshold = UI_getthreshold(EYE);
    if isempty(threshold)
        return
    end
else
    threshold = p.Results.threshold;
end
callstr = sprintf('%s''threshold'', %s)', callstr, all2str(threshold));

for dataidx = 1:numel(EYE)
    fprintf('Identifying saccades in %s...\n', EYE(dataidx).name);
    vel = computevel(EYE(dataidx));
    isSaccade = vel >= threshold;
    fprintf('\t%f%% of points marked as saccades\n', 100*sum(vel >= threshold) / sum(~isnan(vel)));
    EYE(dataidx).datalabel(isSaccade) = 's';
    EYE(dataidx).datalabel(~isSaccade) = 'f';
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
end
fprintf('Done\n');

end

function vel = computevel(EYE)

vel = [];
for dataidx = 1:numel(EYE)
    vel = [vel sqrt(diff(EYE(dataidx).gaze.x).^2 + diff(EYE(dataidx).gaze.y).^2)];
end

end

function threshold = UI_getthreshold(EYE)

vel = computevel(EYE);
[y,edges] = histcounts(vel);
x = edges(1:end-1) + diff(edges)/2;

f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'NumberTitle', 'off',...
    'Name', 'Saccade threshold',...
    'Units', 'normalized',...
    'Position', [0.2 0.2 0.7 0.7],...
    'UserData', struct('x', x, 'y', y, 'vel', vel));
axes(f,...
    'Tag', 'axis',...
    'Units', 'normalized',...
    'Position', [0.11 0.21 0.78 0.68]);
uicontrol('Style', 'edit',...
    'Tag', 'threshold',...
    'String', 'Select saccade threshold',...
    'Units', 'normalized',...
    'Callback', @(h,e)plotrejection(f),...
    'Position', [0.01 0.01 0.48 0.08]);
uicontrol('Style', 'pushbutton',...
    'Units', 'normalized',...
    'String', 'Accept',...
    'Callback', @(h,e)uiresume(f),...
    'KeyPressFcn', @(h,e)keyresume(e.Key, 'return'),...
    'Position', [0.51 0.01 0.23 0.08]);
uicontrol('Style', 'pushbutton',...
    'Units', 'normalized',...
    'String', 'Cancel',...
    'Callback', @(h,e)delete(f),...
    'KeyPressFcn', @(h,e)keydelete(e.Key, 'return'),...
    'Position', [0.76 0.01 0.23 0.08]);

plot(x, y, 'k');

plotrejection(f)
uiwait(f)
if isgraphics(f)
    teditbox = findobj(f, 'Tag', 'threshold');
    threshold = str2double(teditbox.String);
    close(f)
else
    threshold = [];
end

end

function plotrejection(f)

data = get(f, 'UserData');
x = data.x;
y = data.y;
vel = data.vel;

teditbox = findobj(f, 'Tag', 'threshold');
currThreshold = str2double(teditbox.String);

ax = findobj(f, 'Tag', 'axis');
axes(ax); cla; hold on
plot(data.x, data.y, 'k');
plot(repmat(currThreshold, 1, 2), [min(y) max(y)], '--k')
xlim([min(x) max(x)]);
ppnSaccade = sum(vel >= currThreshold) / sum(~isnan(vel));
title(sprintf('%f%% of points marked as saccade', ppnSaccade*100));
xlabel('Velocity');
ylabel('Datapoint count');

end

function keyresume(key, name)

switch key
    case name
        uiresume(gcbf)
end

end

function keydelete(key, name)

switch key
    case name
        delete(gcbf)
end

end