function EYE = PFEdetrend(EYE, varargin)

p = inputParser;
addParameter(p, 'axis', 'y');
addParameter(p, 'detrendParams', []);
parse(p, varargin{:});

axis = p.Results.axis;

callStr = sprintf('eyeData = %s(eyeData, ''axis'', %s, ', mfilename, all2str(axis));
if isempty(p.Results.detrendParams)
    detrendParams = cell(1, numel(EYE));
    for dataidx = 1:numel(EYE)
        if isfield(EYE(dataidx).diam, 'both')
            currData = EYE(dataidx).diam.both(:);
        else
            currData = nanmean_bc([EYE(dataidx).diam.left(:) EYE(dataidx).diam.right(:)], 2);
        end
        currCoord = EYE(dataidx).gaze.(axis)(:);
        currDetrendParams = UI_getdetrendparams(currCoord, currData, axis, EYE(dataidx).name);
        if isempty(currDetrendParams)
            return
        end
        detrendParams{dataidx} = currDetrendParams;
    end
else
    if ~iscell(detrendParams)
        detrendParams = repmat({detrendParams}, 1, numel(EYE));
    end
end

fprintf('Detrending...\n')
for dataidx = 1:numel(EYE)
    fprintf('\t%s:\n\t', EYE(dataidx).name)
    currDetrendParams = detrendParams{dataidx};
    fprintf('Correcting for the following equation:\n\t');
    if strcmp(axis, 'y')
        fprintf('Diam = C + %f*gaze_y\n', currDetrendParams(1))
    elseif strcmp(axis, 'x')
        fprintf('Diam = C + %f*gaze_x + %f*gaze_x^2\n', currDetrendParams(2), currDetrendParams(1))
    end
    est = polyval(currDetrendParams, EYE(dataidx).gaze.(axis));
    est = est - nanmean_bc(est);
    for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
        EYE(dataidx).diam.(stream{:}) = EYE(dataidx).diam.(stream{:}) - est;
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, sprintf('%s''detrendParams'', %s)', callStr, all2str(currDetrendParams)));
end
fprintf('Done\n')

end

function detrendParams = UI_getdetrendparams(y, d, axis, name)

f = figure(...
    'Name', name,...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'UserData', struct(...
        'y', y,...
        'd', d,...
        'axis', axis));
p1 = uipanel(f,...
    'Tag', 'plotpanel',...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.88]);
axes(p1,...
    'Tag', 'scatter',...
    'NextPlot', 'add')
p = uipanel(f,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.48 0.08]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'lower',...
    'Callback', @(h,e) updateplot,...
    'KeyReleaseFcn', @(h,e) enterdo(e, @updateplot),...
    'String', 'lower cutoff',...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.48 0.98]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'upper',...
    'Callback', @(h,e) updateplot,...
    'KeyReleaseFcn', @(h,e) enterdo(e, @updateplot),...
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

if isvalid(f)
    updateplot(f);
    detrendParams = f.UserData.detrendParams;
    close(f);
else
    detrendParams = [];
end

end

function updateplot(varargin)

if ~isempty(varargin)
    f = varargin{cellfun(@isgraphics, varargin)};
else
    f = gcbf;
end

badIdx = false(size(f.UserData.y));
for limType = {'lower' 'upper'}
    currLim = getlim(f, limType);
    if strcmp(limType, 'lower')
        badIdx = badIdx | f.UserData.y < currLim;
    else
        badIdx = badIdx | f.UserData.y > currLim;
    end
end

y = f.UserData.y(:);
d = f.UserData.d(:);

badIdx = badIdx | isnan(d) | isnan(y);
if strcmp(f.UserData.axis, 'y')
    detrendParams = polyfit(y(~badIdx), d(~badIdx), 1);
elseif strcmp(f.UserData.axis, 'x')
    detrendParams = polyfit(y(~badIdx), d(~badIdx), 2);
end
f.UserData.detrendParams = detrendParams;

axes(findobj(f, 'Type', 'axes', 'Tag', 'scatter'));
cla; hold on
scatter(y(~badIdx), d(~badIdx), 5, 'k', 'filled',...
    'MarkerFaceAlpha', 0.1,...
    'MarkerEdgeAlpha', 0.1)
newLine = polyval(detrendParams, sort(y(~badIdx)));
% newLine = [[min(y(~badIdx)); max(y(~badIdx))] ones(2, 1)] * detrendParams;
% newLine = [y(:) ones(size(d(:)))] * detrendParams;
plot(sort(y(~badIdx)), newLine, 'r');
% plot([min(y(~badIdx)); max(y(~badIdx))], newLine, 'r');
xlabel(['Gaze ' f.UserData.axis]);
ylabel('Pupil diameter');

end

function currLim = getlim(f, limType)

limType = cellstr(limType);
currStr = get(findobj(f, 'Tag', [limType{:}]), 'String');
if ~isempty(strfind(currStr, '%'))
    ppn = str2double(strrep(currStr, '%', ''))/100;
    vec = sort(f.UserData.y);
    vec = vec(~isnan(vec));
    if strcmp(limType, 'lower')
        currLim = vec(max(1, round(ppn*numel(vec))));
    else
        currLim = vec(min(numel(vec), round((1 - ppn)*numel(vec))));
    end
else
    currLim = str2num(currStr);
end

if isempty(currLim)
    if strcmp(limType, 'lower')
        currLim = -inf;
    else
        currLim = inf;
    end
end

end