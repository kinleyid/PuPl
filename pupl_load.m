function structArray = pupl_load(varargin)

% Load eye data or event logs
%   Inputs
% type--data type: see getextfromdatatype for more info
% filenames--cell array
% directory--char
%   Outputs
% structArray--struct array

p = inputParser;
addParameter(p, 'type', [])
addParameter(p, 'filenames', [])
addParameter(p, 'directory', [])
addParameter(p, 'UI', []);
parse(p, varargin{:});

if isempty(p.Results.type)
    dataTypeOptions = {
        'eye data'
        'event logs'};
    dataType = dataTypeOptions(listdlg('PromptString', 'Data type',...
        'ListString', dataTypeOptions));
else
    dataType = p.Results.type;
end
if strcmp(dataType, 'eye data')
    extFilter = '*.eyedata';
elseif strcmp(dataType, 'event logs')
    extFilter = '*.eventlog';
end

if isempty(p.Results.filenames) || isempty(p.Results.filenames)
    [filenames, directory] = uigetfile(extFilter,...
        'MultiSelect', 'on');
else
    filenames = p.Results.filenames;
    directory = p.Results.directory;
end
filenames = cellstr(filenames);

structArray = [];
for fileIdx = 1:numel(filenames)
    data = load([directory '\\' filenames{fileIdx}], '-mat');
    savedStructs = fieldnames(data);
    for sIdx = 1:numel(savedStructs)
        structArray = [structArray data.(savedStructs{sIdx})];
    end
end

if ~isempty(p.Results.UI)
    if strcmp(dataType, 'eye data')
        p.Results.UI.UserData.EYE = cat(2, p.Results.UI.UserData.EYE, structArray);
        writetopanel(p.Results.UI, 'datasetinfo', {structArray.name});
    elseif strcmp(dataType, 'event logs')
        p.Results.UI.UserData.eventLogs = cat(2, p.Results.UI.UserData.eventLogs, structArray);
        writetopanel(p.Results.UI, 'eventlogsinfo', {structArray.name});
    end
    p.Results.UI.Visible = 'off';
    p.Results.UI.Visible = 'on';
end

end