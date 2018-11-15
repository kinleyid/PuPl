function pupl_UI

mainFigure = uifigure('Name', 'Pupillometry',...
    'UserData', struct('EYE', [], 'eventLogs', []),...
    'AutoResizeChildren', 'off',...
    'SizeChangedFcn', @preserveLayout,...
    'Visible', 'off');

% Info on datasets, event logs, processing history

dataSetInfo = uipanel('Parent', mainFigure,...
    'Tag', 'datasetinfo',...
    'Title', 'Datasets');
uitextarea(dataSetInfo,...
    'Editable', 'off');
eventLogsInfo = uipanel('Parent', mainFigure,...
    'Tag', 'eventlogsinfo',...
    'Title', 'Event logs');
uitextarea(eventLogsInfo, 'Editable', 'off');
processingHistory = uipanel('Parent', mainFigure,...
    'Tag', 'processinghistory',...
    'Title', 'Processing history');
uitextarea(processingHistory, 'Editable', 'off');

% Data menu
fileMenu = uimenu(mainFigure,...
    'Tag', 'fileMenu',...
    'Text', '&Data');
uimenu(fileMenu,...
    'Text', '&Import',...
    'MenuSelectedFcn', @(src, event) pupl_format('type', 'eye data', 'UI', mainFigure));
uimenu(fileMenu,...
    'Text', '&Load formatted',...
    'MenuSelectedFcn', @(src, event) pupl_load('type', 'eye data', 'UI', mainFigure));
uimenu(fileMenu,...
    'Text', '&Save formatted',...
    'MenuSelectedFcn', @(src, event) pupl_save('type', 'eye data', 'data', mainFigure.UserData.EYE));

% Processing menu
processingMenu = uimenu(mainFigure, 'Text', '&Process');
uimenu(processingMenu,...
    'Text', '&Moving average filter',...
    'MenuSelectedFcn', @(src, event) eyefilter(mainFigure.UserData.EYE, 'UI', mainFigure),...
    'Interruptible', 'off');
uimenu(processingMenu,...
    'Text', '&Interpolate',...
    'MenuSelectedFcn', @(src, event) interpeyedata(mainFigure.UserData.EYE, 'UI', mainFigure),...
    'Interruptible', 'off');
uimenu(processingMenu,...
    'Text', '&Merge left and right streams',...
    'MenuSelectedFcn', @(src, event) mergelr(mainFigure.UserData.EYE, 'UI', mainFigure),...
    'Interruptible', 'off');

% Epoching menu
epochingMenu = uimenu(mainFigure,...
    'Text', '&Trials');
uimenu(epochingMenu,...
    'Text', '&Separate into trials',...
    'MenuSelectedFcn', @(src, event) epoch(mainFigure.UserData.EYE, 'UI', mainFigure),...
    'Interruptible', 'off');
uimenu(epochingMenu,...
    'Text', '&Combine trials into sets',...
    'MenuSelectedFcn', @(src, event) binepochs(mainFigure.UserData.EYE, 'UI', mainFigure),...
    'Interruptible', 'off');
    
% Event logs menu
eventLogsMenu = uimenu(mainFigure, 'Text', '&Event logs');
uimenu(eventLogsMenu,...
    'Text', '&Import',...
    'MenuSelectedFcn', @(src, event) pupl_format('type', 'event logs', 'UI', mainFigure));
uimenu(eventLogsMenu,...
    'Text', '&Load formatted',...
    'MenuSelectedFcn', @(src, event) pupl_load('type', 'event logs', 'UI', mainFigure));
uimenu(eventLogsMenu,...
    'Text', '&Save formatted',...
    'MenuSelectedFcn', @(src, event) pupl_save('type', 'eye data', 'data', mainFigure.UserData.eventLogs));
uimenu(eventLogsMenu,...
    'Text', '&Write events to eye data',...
    'MenuSelectedFcn', @(src, event) pupl_save(mainFigure.UserData.EYE, 'eventLogs', mainFigure.UserData.eventLogs));

% Spreadsheet menu
spreadSheetMenu = uimenu(mainFigure,...
    'Text', '&Spreadsheet');
uimenu(spreadSheetMenu,...
    'Text', '&Write eye data to spreadsheet',...
    'MenuSelectedFcn', @(src, event) writetospreadsheet(mainFigure.UserData.EYE));

mainFigure.Visible = 'on';

end

function preserveLayout(varargin)

panelTags = {'datasetinfo' 'eventlogsinfo' 'processinghistory'};

UI = varargin{1};

sep = 10;
panelWidth = (UI.Position(3) - 4*sep)/3;
panelHeight = UI.Position(4) - 2*sep;

for i = 1:numel(panelTags)
    panelIdx = strcmpi(panelTags(i), arrayfun(@(x) x.Tag, UI.Children, 'un', 0));
    newPosition = [(i*sep + (i-1)*panelWidth) sep panelWidth panelHeight];
    UI.Children(panelIdx).Position = newPosition;
    % Change location of text boxes
    UI.Children(panelIdx).Children(1).Position = [sep sep newPosition(3)-2*sep newPosition(4)-4*sep];
end

end