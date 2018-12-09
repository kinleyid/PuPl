function EYE = PFEdetrend(EYE, varargin)

p = inputParser;
addParameter(p, 'slope', []);
parse(p, varargin{:});

fprintf('Detrending...\n')
for dataIdx = 1:numel(EYE)
    fprintf('%s\n', EYE(dataIdx).name)
    if isfield(EYE(dataIdx), 'both')
        currData = EYE(dataIdx).data.both(:);
    else
        currData = mean([EYE(dataIdx).data.left(:) EYE(dataIdx).data.right(:)], 2, 'omitnan');
    end
    currCoord = EYE(dataIdx).gaze.y(:);
    if isempty(p.Results.slope)
        slope = UI_getdetrendparams(currCoord, currData);
        if isempty(slope)
            EYE = [];
            return
        end
    else
        slope = p.Results.slope;
    end
    fprintf('\tCorrecting for the following equation:\n');
    fprintf('\tDiam = C + %f*gaze_y\n', slope)
    est = EYE(dataIdx).gaze.y*slope;
    est = est - mean(est, 'omitnan');
    for stream = reshape(fieldnames(EYE(dataIdx).data), 1, [])
        EYE(dataIdx).data.(stream{:}) = EYE(dataIdx).data.(stream{:}) - est;
    end
end

end

function slope = UI_getdetrendparams(y, d)

f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'UserData', struct(...
        'y', y,...
        'd', d));
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
    slope = f.UserData.detrendParams(1);
    close(f);
else
    slope = [];
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
detrendParams = [y(~badIdx) ones(size(y(~badIdx)))] \ d(~badIdx);
f.UserData.detrendParams = detrendParams;

axes(findobj(f, 'Type', 'axes', 'Tag', 'scatter'));
cla; hold on
scatter(y(~badIdx), d(~badIdx), 5, 'k', 'filled',...
    'MarkerFaceAlpha', 0.1,...
    'MarkerEdgeAlpha', 0.1)
newLine = [[min(y(~badIdx)); max(y(~badIdx))] ones(2, 1)] * detrendParams;
% newLine = [y(:) ones(size(d(:)))] * detrendParams;
plot([min(y(~badIdx)); max(y(~badIdx))], newLine, 'r');

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