function EYE = rejecttrialsbymissingppn(EYE, varargin)

%   Inputs
% EYE--struct array
%   Outputs
% EYE--struct array

p = inputParser;
addParameter(p, 'threshold', []);
parse(p, varargin{:});

if isempty(p.Results.threshold)
    threshold = UI_getrejectionthreshold(EYE);
    if isempty(threshold)
        EYE = [];
        return
    end
else
    threshold = p.Results.threshold;
end

fprintf('Rejecting trials with >= %0.1f%% missing data...\n', threshold*100);

missingPpns = getmissingppns(EYE);

for dataIdx = 1:numel(EYE)
    nRej = 0;
    for epochIdx = 1:numel(EYE(dataIdx).epoch)
        if missingPpns{dataIdx}(epochIdx) >= threshold
            EYE(dataIdx).epoch(epochIdx).reject = true;
            nRej = nRej + 1;
        end
    end
    fprintf('\t%s:\n\t\t%d/%d trials rejected\n',...
        EYE(dataIdx).name,...
        nRej,...
        numel(EYE(dataIdx).epoch));
    fprintf('\t\t%d trials total marked for rejection\n', nnz([EYE(dataIdx).epoch.reject]));
end

fprintf('Done\n')

end

function threshold = UI_getrejectionthreshold(EYE)

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
    'Tag', 'threshold',...
    'String', 'Select rejection proportion',...
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

teditbox = findobj(f, 'Tag', 'threshold');
currThreshold = str2double(teditbox.String);

missingPpns = cell2mat(getmissingppns(f.UserData.data));

proportions = 0:0.01:1;   
ppnViolating = sum(bsxfun(@ge, missingPpns', proportions))/numel(missingPpns);
currPpnViolating = nnz(missingPpns >= currThreshold)/numel(missingPpns);
ax = findobj(f, 'Tag', 'axis');
axes(ax); cla; hold on
plot(proportions, ppnViolating, 'k');
plot(repmat(currThreshold, 1, 2), [0 1], '--k')
plot([0 1], repmat(currPpnViolating, 1, 2), '--k')
xlim([0 1]);
ylim([0 1]);
title('Poportion of trials rejected as a function of rejection threshold');
xlabel('Missing values threshold (proportion)');
ylabel('Proportion of trials violating threshold');

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