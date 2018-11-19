function pupl_UI

global userInterface activeEyeDataPanel activeEventLogsPanel

userInterface = figure('Name', 'Pupillometry',...
    'NumberTitle', 'off',...
    'UserData', struct(...
        'dataCount', 0,...
        'eventLogCount', 0),...
    'SizeChangedFcn', @preservelayout,...
    'DeleteFcn', @savewarning,...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'Visible', 'off');

% Active datasets
activeEyeDataPanel = uibuttongroup('Title', 'Active datasets',...
    'Position',[0.01 0.01 .48 0.95],...
    'FontSize', 10);
activeEventLogsPanel = uibuttongroup('Title', 'Active event logs',...
    'Position',[0.51 0.01 .48 0.95],...
    'FontSize', 10);

% File menu
fileMenu = uimenu(userInterface,...
    'Tag', 'fileMenu',...
    'Text', '&File');
uimenu(fileMenu,...
    'Text', '&Import',...
    'MenuSelectedFcn', @(h, e)...
        globalHelper(pupl_format('type', 'eye data'), 'append'));
uimenu(fileMenu,...
    'Text', '&Load',...
    'MenuSelectedFcn', @(h, e)...
        globalHelper(pupl_load('type', 'eye data'), 'append'));
uimenu(fileMenu,...
    'Text', '&Save',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(pupl_save('type', 'eye data', 'data', getactiveeyedata)));
uimenu(fileMenu,...
    'Text', '&Remove active datasets',...
    'Separator', 'on',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(deleteactive('eye data')));

% Processing menu
processingMenu = uimenu(userInterface, 'Text', '&Process');
uimenu(processingMenu,...
    'Text', 'Identify &blinks',...
    'Interruptible', 'off',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(identifyblinks(getactiveeyedata)));
uimenu(processingMenu,...
    'Text', '&Moving average filter',...
    'Interruptible', 'off',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(eyefilter(getactiveeyedata)));
uimenu(processingMenu,...
    'Text', '&Interpolate',...
    'Interruptible', 'off',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(interpeyedata(getactiveeyedata)));
uimenu(processingMenu,...
    'Text', '&Merge left and right streams',...
    'Interruptible', 'off',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(mergelr(getactiveeyedata)));

% Epoching menu
trialsMenu = uimenu(userInterface,...
    'Text', '&Trials');
uimenu(trialsMenu,...
    'Text', '&Separate into trials',...
    'Interruptible', 'off',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(epoch(getactiveeyedata)));
uimenu(trialsMenu,...
    'Text', '&Merge trials',...
    'Interruptible', 'off',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(binepochs(getactiveeyedata)));
% Event logs sub-menu
eventLogsMenu = uimenu(trialsMenu,...
    'Text', '&Event logs');
uimenu(eventLogsMenu,...
    'Text', '&Write to eye data',...
    'Interruptible', 'off',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(attachevents(getactiveeyedata, 'eventLogs', geteventlogs)));
uimenu(eventLogsMenu,...
    'Text', '&Import',...
    'Separator', 'on',...
    'Interruptible', 'off',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(pupl_format('type', 'event logs'), 'append'));
uimenu(eventLogsMenu,...
    'Text', '&Load',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(pupl_load('type', 'event logs'), 'append'));
uimenu(eventLogsMenu,...
    'Text', '&Save',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(pupl_save('type', 'eye data', 'data', geteventlogs)));
uimenu(eventLogsMenu,...
    'Text', '&Remove active event logs',...
    'Separator', 'on',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(deleteactive('event logs')));
    
% Experiment menu
experimentMenu = uimenu(userInterface,...
    'Text', '&Experiment');
uimenu(experimentMenu,...
    'Text', '&Assign datasets to conditions',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(pupl_condition(getactiveeyedata)));
uimenu(experimentMenu,...
    'Text', '&Merge conditions',...
    'MenuSelectedFcn', @(src, event)...
        globalHelper(pupl_merge(getactiveeyedata)));

% Plotting menu
plottingMenu = uimenu(userInterface,...
    'Text', 'P&lot');
uimenu(plottingMenu,...
    'Text', 'Plot &continuous',...
    'MenuSelectedFcn', @(src, event)...
        plotcontinuous(getactiveeyedata));
plotTrialsMenu = uimenu(plottingMenu,...
    'Text', 'Plot &trials');
uimenu(plotTrialsMenu,...
    'Text', '&Line plot',...
    'MenuSelectedFcn', @(src, event)...
        plottrials(getactiveeyedata));
uimenu(plotTrialsMenu,...
    'Text', '&Heatmap',...
    'MenuSelectedFcn', @(src, event)...
        eyeheatmap(getactiveeyedata));
uimenu(plottingMenu,...
    'Text', 'Pupil &foreshortening heatmap',...
    'MenuSelectedFcn', @(h, e)...
        PFEplot(getactiveeyedata));

% Spreadsheet menu
spreadSheetMenu = uimenu(userInterface,...
    'Text', '&Spreadsheet');
uimenu(spreadSheetMenu,...
    'Text', '&Write eye data to spreadsheet',...
    'MenuSelectedFcn', @(src, event)...
        writetospreadsheet(getactiveeyedata));

userInterface.Visible = 'on';
    
end

function globalHelper(in, varargin)

global eyeData activeEyeDataIdx eventLogs activeEventLogsIdx

if ~isempty(in)
    dataType = in(1).type;
    if ~isempty(in)
        if strcmp(dataType, 'eye data')
            currStruct = eyeData;
            activeIdx = activeEyeDataIdx;
        elseif strcmp(dataType, 'event logs')
            currStruct = eventLogs;
            activeIdx = activeEventLogsIdx;
        end
        if ~isempty(currStruct)
            % Create empty fields if necessary so that structs can still be in an array
            [currStruct, in] = fieldconsistency(currStruct, in);
            if any(strcmpi(varargin, 'append'))
                currStruct = [currStruct in];
            else
                currStruct(activeIdx) = in;
            end
        else
            currStruct = in;
        end
        if strcmp(dataType, 'eye data')
            eyeData = currStruct;
            activeEyeDataIdx = activeIdx;
        elseif strcmp(dataType, 'event logs')
            eventLogs = currStruct;
            activeEventLogsIdx = activeIdx;
        end
    end
end

update_UI

end

function update_UI

% For when new data is loaded or the active datasets change

global userInterface 
global activeEyeDataPanel activeEyeDataIdx eyeData 
global activeEventLogsPanel activeEventLogsIdx eventLogs

if userInterface.UserData.dataCount ~= numel(eyeData) || userInterface.UserData.eventLogCount ~= numel(eventLogs)
    % Data added or deleted
    userInterface.UserData.dataCount = numel(eyeData);
    userInterface.UserData.eventLogCount = numel(eventLogs);
    preservelayout
end

for i = 1:numel(activeEyeDataPanel.Children)
    if activeEyeDataPanel.Children(i).Value == 1
        activeEyeDataIdx(numel(activeEyeDataPanel.Children) + 1 - i) = true;
    else
        activeEyeDataIdx(numel(activeEyeDataPanel.Children) + 1 - i) = false;
    end
end
activeEyeDataIdx = logical(activeEyeDataIdx);



for i = 1:numel(activeEventLogsPanel.Children)
    if activeEventLogsPanel.Children(i).Value == 1
        activeEventLogsIdx(numel(activeEventLogsPanel.Children) + 1 - i) = true;
    else
        activeEventLogsIdx(numel(activeEventLogsPanel.Children) + 1 - i) = false;
    end
end
activeEventLogsIdx = logical(activeEventLogsIdx);

userInterface.Visible = 'off';
userInterface.Visible = 'on';

end

function out = getactiveeyedata

global eyeData activeEyeDataIdx
out = eyeData(activeEyeDataIdx);

end

function out = geteventlogs

global eventLogs activeEventLogsIdx
out = eventLogs(activeEventLogsIdx);

end

function preservelayout(varargin)

sep = 2;
buttonHeight = 20;

global eyeData activeEyeDataPanel activeEyeDataIdx
global eventLogs activeEventLogsPanel activeEventLogsIdx

allData = {eyeData eventLogs};
allPanels = {activeEyeDataPanel activeEventLogsPanel};
allActiveIdx = {activeEyeDataIdx activeEventLogsIdx};

for idx = 1:numel(allData)
    currData = allData{idx};
    currPanel = allPanels{idx};
    currActiveIdx = allActiveIdx{idx};
    if ~isempty(currPanel.Children)
        delete(currPanel.Children)
    end
    currActiveIdx(numel(currActiveIdx)+1:numel(currData)) = true;
    bgPos = getpixelposition(currPanel);
    top = bgPos(4) - buttonHeight;
    buttonWidth = bgPos(3) - sep;
    for i = 1:numel(currData)
        if currActiveIdx(numel(currData) + 1 - i)
            value = 1;
        else
            value = 0;
        end
        uicontrol(currPanel,...
            'Style', 'checkbox',...
            'Position', [sep, top - (buttonHeight+sep)*i, buttonWidth, buttonHeight],...
            'String', currData(i).name,...
            'Value', value,...
            'FontSize', 10,...
            'Callback', @(h, e) update_UI);
    end
end

end

function savewarning(varargin)

global eyeData eventLogs
if ~isempty(eyeData) || ~isempty(eventLogs)
    q = 'Save data from workspace?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');

    if strcmp(a, 'Yes')
        data = {eyeData eventLogs};
        types = {'eye data' 'event logs'};
        for i = 1:numel(data)
            if ~isempty(data{i})
                pupl_save('data', data{i}, 'type', types{i});
            end
        end
    end
end

end

function void = deleteactive(dataType)

void = [];

global eyeData activeEyeDataIdx eventLogs activeEventLogsIdx

if strcmpi(dataType, 'eye data')
    for currData = reshape(eyeData(activeEyeDataIdx), 1, [])
        fprintf('Removing %s\n', currData.name);
    end
    eyeData(activeEyeDataIdx) = [];
    activeEyeDataIdx(activeEyeDataIdx) = [];
elseif strcmpi(dataType, 'event logs')
    for currData = reshape(eventLogs(activeEventLogsIdx), 1, [])
        fprintf('Removing %s\n', currData.name);
    end
    eventLogs(activeEventLogsIdx) = [];
    activeEventLogsIdx(activeEventLogsIdx) = [];
end

end