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

% Convert string limits to numerical limits

lims = [leftLims(:)' rightLims(:)'];
fs([1 3]) = {@lt};
fs([2 4]) = {@gt};
sides([1 3]) = {'left'};
sides([2 4]) = {'right'};

fprintf('Trimming extreme pupil diameter values...\n')
fprintf('Trimming points where\n')
fprintf('Left < %s\n', lims{1});
fprintf('Left > %s\n', lims{2});
fprintf('Right  < %s\n', lims{3});
fprintf('Right > %s\n', lims{4});

for dataidx = 1:numel(EYE)
    badidx = false(1, EYE(dataidx).ndata);
    for ii = 1:4
        data = EYE(dataidx).diam.(sides{ii});
        lim = parsedatastr(lims{ii}, data);
        badidx = badidx | feval(fs{ii}, data, lim);
    end
    for field1 = {'gaze' 'diam'} 
        for field2 = reshape(fieldnames(EYE(dataidx).(field1{:})), 1, [])
            EYE(dataidx).(field1{:}).(field2{:})(badidx) = nan; 
        end
    end
    fprintf('\t%s: %0.2f%% of data removed\n', EYE(dataidx).name, 100*nnz(badidx)/numel(EYE(dataidx).isBlink))
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
end
fprintf('Done\n')

end

function [leftLims, rightLims] = UI_getdiamlims(EYE)

if numel(EYE) > 1
    % Map means onto mean of means
    fprintf('Multiple datasets being passed to trimdiam\nMapping means onto mean of means for plotting');
    means = struct(...
        'left', 0,...
        'right', 0);
    for dataidx = 1:numel(EYE)
        for field = reshape(fieldames(EYE(dataidx).diam), 1, [])
            means.(field{:}) = means.(field{:})...
                + nanmean_bc(EYE(dataidx).diam.(field{:})) / numel(EYE);
        end
    end
    for dataidx = 1:numel(EYE)
        for field = reshape(fieldames(EYE(dataidx).diam), 1, [])
            EYE(dataidx).diam.(field{:}) = EYE(dataidx).diam.(field{:})...
                + means.(field{:}) - nanmean_bc(EYE(dataidx).diam.(field{:}));
        end
    end
else
    left = mergefields(EYE, 'diam', 'left');
    right = mergefields(EYE, 'diam', 'right');
end

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

if isgraphics(f)
    [~, leftLims{1}] = getlim(f, 'left', 'Lower');
    [~, leftLims{2}] = getlim(f, 'left', 'Upper');
    [~, rightLims{1}] = getlim(f, 'right', 'Lower');
    [~, rightLims{2}] = getlim(f, 'right', 'Upper');
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

UserData = get(f, 'UserData');

badIdx = struct(...
    'left', false(size(UserData.left)),...
    'right', false(size(UserData.right)));

for side = {'left' 'right'}
    for limType = {'Lower' 'Upper'}
        currLim = getlim(f, side, limType);
        if strcmp(limType, 'Lower')
            badIdx.(side{:}) = badIdx.(side{:}) | UserData.(side{:}) < currLim;
        else
            badIdx.(side{:}) = badIdx.(side{:}) | UserData.(side{:}) > currLim;
        end
    end
end
left = UserData.left;
right = UserData.right;

badIdx.both = badIdx.right | badIdx.left;
axes(findobj(f, 'Type', 'axes', 'Tag', 'hist'));
cla;
bins = linspace(min([left right]), max([left right]), 200);
try
    for side = {'left' 'right'}
        histogram(UserData.(side{:}), bins);
    end
    for side = {'left' 'right'}
        histogram(UserData.(side{:})(badIdx.(side{:})), bins, 'FaceColor', 'k');
    end
    legend({'Left' 'Right' 'Trimmed'})
catch
    for side = {'left' 'right'}
        hist(UserData.(side{:}), bins);
    end
    h = findobj(gca,'Type','patch');
    set(h,'FaceAlpha', 0.0, 'EdgeColor','k')
end
xlabel('Diameter')

title(sprintf('%0.2f%% trimmed', 100*nnz(badIdx.both)/numel(badIdx.both)));

set(f, 'UserData', UserData);

end

function [currLim, currStr] = getlim(f, side, limType)

UserData = get(f, 'UserData');

side = cellstr(side);
limType = cellstr(limType);
currStr = get(findobj(f, 'Tag', [side{:} limType{:}]), 'String');
currLim = parsedatastr(currStr, UserData.(side{:}));

end