function EYE = rejectbyextremevalues(EYE, varargin)

p = inputParser;
addParameter(p, 'lims', []);
parse(p, varargin{:});

if isempty(p.Results.lims)
    lims = UI_getextremevaluelims(EYE);
    if isempty(lims)
        return
    end
else
    lims = p.Results.lims;
end

fprintf('Rejecting trials with data values <= %0.2f or >= %0.2f...\n', lims(1), lims(2));

for dataIdx = 1:numel(EYE)
    nRej = 0;
    for epochIdx = 1:numel(EYE(dataIdx).epoch)
        isRej = false;
        for field = {'left' 'right'}
            if any(EYE(dataIdx).epoch(epochIdx).data.(field{:}) <= lims(1))...
                    || any(EYE(dataIdx).epoch(epochIdx).data.(field{:}) >= lims(2))
                EYE(dataIdx).epoch(epochIdx).reject = true;
                isRej = true;
            end
        end
        if isRej
            nRej = nRej + 1;
        end
    end
    fprintf('%s:\n\t%d/%d trials rejected\n',...
        EYE(dataIdx).name,...
        nRej,...
        numel(EYE(dataIdx).epoch));
    fprintf('\t%d trials total marked for rejection\n', nnz([EYE(dataIdx).epoch.reject]));
end

end

function lims = UI_getextremevaluelims(EYE)

%   Inputs
% EYE--struct array
%   Outputs
% threshold--double

f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'NumberTitle', 'off',...
    'Name', 'Rejection threshold',...
    'Units', 'normalized',...
    'Position', [0.2 0.2 0.7 0.7],...
    'UserData', struct('data', EYE));

axes(f,...
    'Tag', 'axis',...
    'Units', 'normalized',...
    'Position', [0.11 0.21 0.78 0.68]);

uicontrol('Style', 'edit',...
    'Tag', 'lowerlim',...
    'String', 'Lower limit',...
    'Units', 'normalized',...
    'Callback', @(h,e)plotrejection(f),...
    'Position', [0.01 0.01 0.23 0.08]);
uicontrol('Style', 'edit',...
    'Tag', 'upperlim',...
    'String', 'Upper limit',...
    'Units', 'normalized',...
    'Callback', @(h,e)plotrejection(f),...
    'Position', [0.26 0.01 0.23 0.08]);
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

plotrejection(f)
uiwait(f)
if isgraphics(f)
    teditbox = findobj(f, 'Tag', 'lowerlim');
    lowerlim = str2double(teditbox.String);
    teditbox = findobj(f, 'Tag', 'upperlim');
    upperlim = str2double(teditbox.String);
    lims = [lowerlim upperlim];
    close(f)
else
    lims = [];
end

end

function plotrejection(f)

teditbox = findobj(f, 'Tag', 'lowerlim');
lowerlim = str2double(teditbox.String);
teditbox = findobj(f, 'Tag', 'upperlim');
upperlim = str2double(teditbox.String);
allEpochData = [mergefields(f.UserData.data, 'epoch', 'data', 'left')...
                mergefields(f.UserData.data, 'epoch', 'data', 'right')];
ax = findobj(f, 'Tag', 'axis');
axes(ax); cla; hold on
edges = linspace(min(allEpochData), max(allEpochData), 100);
histogram(allEpochData, edges)
histogram(allEpochData(allEpochData >= upperlim), edges, 'FaceColor', 'r')
histogram(allEpochData(allEpochData <= lowerlim), edges, 'FaceColor', 'r')
title('Data distribution for trials');
xlabel('Measured value');
ylabel('Number of data points');

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