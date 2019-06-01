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

structArray = struct([]);

if isempty(p.Results.type)
    dataTypeOptions = {
        'eye data'
        'event logs'};
    dataType = dataTypeOptions(listdlg('PromptString', 'Data type',...
        'ListString', dataTypeOptions));
    if isempty(dataType)
        return
    end
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
    if isnumeric(filenames)
        return
    end
else
    filenames = p.Results.filenames;
    directory = p.Results.directory;
end

if isnumeric(filenames)
    return
else
    filenames = cellstr(filenames);
end

for fileIdx = 1:numel(filenames)
    fprintf('Loading %s\n', filenames{fileIdx});
    data = load([directory '\\' filenames{fileIdx}], '-mat');
    structArray = fieldconsistency(structArray, data.data);
    structArray = cat(2, structArray, data.data);
end

structArray = pupl_check(structArray);

fprintf('Done\n');

end