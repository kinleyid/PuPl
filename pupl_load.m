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

if isnumeric(filenames)
    return
else
    filenames = cellstr(filenames);
end

structArray = [];
for fileIdx = 1:numel(filenames)
    data = load([directory '\\' filenames{fileIdx}], '-mat');
    structArray = fieldconsistency(structArray, data.data);
    structArray = cat(2, structArray, data.data);
end

end