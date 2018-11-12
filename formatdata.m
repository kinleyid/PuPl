function structArray = formatdata(varargin)

% Loads data from various formats, saves to 

% Optional args: filenames, directory, formats, saveto

p = inputParser;
addParameter(p, 'filenames', []);
addParameter(p, 'directory', []);
addParameter(p, 'format', []);
addParameter(p, 'saveto', []);
parse(p, varargin{:})

% Use UI to get missing arguments

dataTypes = [];
dataTypes(1).name = 'eye data';
dataTypes(1).formats = {
    'Tobii Excel files'
    'EXF files from The Eye Tribe'};
dataTypes(2).name = 'event logs';
dataTypes(2).formats = {
    'Noldus Excel files'
    'Presentation .log files'
    'E-DataAid Excel files'};

if isempty(p.Results.format)
    dataTypeIdx = listdlg('PromptString', 'Data type',...
        'ListString', {dataTypes.name});
    dataFormat = listdlg('PromptString', 'File format',...
        'ListString', dataTypes(dataTypeIdx).formats);
else
    dataFormat = p.Results.format;
    dataTypeIdx = arrayfun(@(x) any(strcmpi(p.Results.format, x.formats)), dataTypes);
end

if ~any(dataTypeIdx)
    error('Unknown format ''%s''', p.Results.format)
end

if isempty(p.Results.directory) || isempty(p.Results.filenames)
    uiwait(msgbox(sprintf('Select the %s to format', dataTypes(dataTypeIdx).name)));
    [dataFiles, dataDirectory] = uigetfile('./*.*', ...
        sprintf('Select the %s', dataTypes(dataTypeIdx).name),...
        'MultiSelect','on');
else
    dataFiles = p.Results.filenames;
    dataDirectory = p.Results.directory;
end
dataFiles = cellstr(dataFiles);

if numel(dataFormat) == 1 % Potentially many different formats--is this really necessary?
    dataFormat = repmat(dataFormat, numel(dataFiles, 1));
end

structArray = [];
for fileIdx = 1:numel(dataFiles)
    structArray(fileIdx) = loadrawdata(dataType,...
        dataFiles{fileIdx},...
        dataDirectory,...
        dataFormat{fileIdx});
end

if isempty(p.Results.saveto)
    answer = questdlg(sprintf('Save formatted %s?', dataTypes(dataTypeIdx).name),...
        'Save formatted eye files?',...
        'Yes', 'No', 'Yes');
    if strcmp(answer, 'Yes')
        saveDirectory = uigetdir(dataDirectory,...
            'Select a directory to save the formatted eye data to');
    else
        saveDirectory = 0;
    end
elseif p.Results.saveto == 0
    saveDirectory = 0;
else
    saveDirectory = p.Results.directory;
end

if saveDirectory ~= 0
    for currEYE = structArray
        save([saveDirectory '\' currEYE.name '.eyedata'], 'currEYE');
    end
end