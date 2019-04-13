function EYE = trimdiam(EYE, varargin)

p = inputParser;
addParameter(p, 'leftLims', [])
addParameter(p, 'rightLims', [])
parse(p, varargin{:});

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);
if isempty(p.Results.leftLims) || isempty(p.Results.rightLims)
    [leftLims, rightLims] = UI_getdiamlims(EYE);
    if isempty(leftLims)
        EYE = [];
        return
    end
else
    leftLims = p.Results.leftLims;
    rightLims = p.Results.rightLims;
end
callStr = sprintf('%s''leftLims'', %s, ''rightLims'', %s)', callStr, all2str(leftLims), all2str(rightLims));

fprintf('Trimming extreme pupil diameter values...\n')
fprintf('Trimming points where\n')
fprintf('Left < %0.1f\n', leftLims(1));
fprintf('Left > %0.1f\n', leftLims(2));
fprintf('Right  < %0.1f\n', rightLims(1));
fprintf('Right > %0.1f\n', rightLims(2));

for dataIdx = 1:numel(EYE)
    badIdx = EYE(dataIdx).diam.left < leftLims(1) |...
        EYE(dataIdx).diam.left > leftLims(2) |...
        EYE(dataIdx).diam.right < rightLims(1) |...
        EYE(dataIdx).diam.right > rightLims(2);
    for field1 = {'gaze' 'diam'} 
        for field2 = reshape(fieldnames(EYE(dataIdx).(field1{:})), 1, [])
            EYE(dataIdx).(field1{:}).(field2{:})(badIdx) = nan; 
        end
    end
    fprintf('\t%s: %0.2f%% of data removed\n', EYE(dataIdx).name, 100*nnz(badIdx)/numel(EYE(dataIdx).isBlink))
    EYE(dataIdx).history = cat(1, EYE(dataIdx).history, callStr);
end
fprintf('Done\n')

end

function [leftLims, rightLims] = UI_getdiamlims(EYE)

left = mergefields(EYE, 'diam', 'left');
right = mergefields(EYE, 'diam', 'right');

f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'UserData', struct(...
        'left', left,...
        'right', right,...
        'leftLims', [min(left) max(left)],...
        'rightLims', [min(right) max(right)]));
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
    'Tag', 'leftLower',...
    'Callback', @(h,e) updateplot,...
    'String', 'left lower cutoff',...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.24 0.98]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'leftUpper',...
    'Callback', @(h,e) updateplot,...
    'String', 'left upper cutoff',...
    'Units', 'normalized',...
    'Position', [0.26 0.01 0.24 0.98]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'rightLower',...
    'Callback', @(h,e) updateplot,...
    'String', 'right lower cutoff',...
    'Units', 'normalized',...
    'Position', [0.51 0.01 0.24 0.98]);
uicontrol(p,...
    'Style', 'edit',...
    'Tag', 'rightUpper',...
    'Callback', @(h,e) updateplot,...
    'String', 'right upper cutoff',...
    'Units', 'normalized',...
    'Position', [0.76 0.01 0.24 0.98]);
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
    leftLims = [getlim(f, 'left', 'Lower') getlim(f, 'left', 'Upper')];
    rightLims = [getlim(f, 'right', 'Lower') getlim(f, 'right', 'Upper')];
    close(f);
else
    [leftLims, rightLims] = deal([]);
end

end

function updateplot(varargin)

if ~isempty(varargin)
    f = varargin{cellfun(@isgraphics, varargin)};
else
    f = gcbf;
end

badIdx = struct(...
    'left', false(size(f.UserData.left)),...
    'right', false(size(f.UserData.right)));

for side = {'left' 'right'}
    for limType = {'Lower' 'Upper'}
        currLim = getlim(f, side, limType);
        if strcmp(limType, 'Lower')
            badIdx.(side{:}) = badIdx.(side{:}) | f.UserData.(side{:}) < currLim;
        else
            badIdx.(side{:}) = badIdx.(side{:}) | f.UserData.(side{:}) > currLim;
        end
    end
end
left = f.UserData.left;
right = f.UserData.right;

badIdx.both = badIdx.right | badIdx.left;
axes(findobj(f, 'Type', 'axes', 'Tag', 'hist'));
cla;
bins = linspace(min([left right]), max([left right]), 200);
try
    for side = {'left' 'right'}
        histogram(f.UserData.(side{:}), bins);
    end
    for side = {'left' 'right'}
        histogram(f.UserData.(side{:})(badIdx.(side{:})), bins, 'FaceColor', 'k');
    end
    legend({'Left' 'Right' 'Trimmed'})
catch
    for side = {'left' 'right'}
        hist(f.UserData.(side{:}), bins);
    end
    h = findobj(gca,'Type','patch');
    set(h,'FaceAlpha', 0.0, 'EdgeColor','k')
end
xlabel('Diameter')

title(sprintf('%0.2f%% trimmed', 100*nnz(badIdx.both)/numel(badIdx.both)));

end

function currLim = getlim(f, side, limType)

side = cellstr(side);
limType = cellstr(limType);
currStr = get(findobj(f, 'Tag', [side{:} limType{:}]), 'String');
if ~isempty(strfind(currStr, '%'))
    ppn = str2double(strrep(currStr, '%', ''))/100;
    vec = sort(f.UserData.(side{:}));
    vec = vec(~isnan(vec));
    if strcmp(limType, 'Lower')
        currLim = vec(max(1, round(ppn*numel(vec))));
    else
        currLim = vec(min(numel(vec), round((1 - ppn)*numel(vec))));
    end
else
    currLim = str2num(currStr);
end

if isempty(currLim)
    if strcmp(limType, 'Lower')
        currLim = -inf;
    else
        currLim = inf;
    end
end

end