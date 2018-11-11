function data = formatdata(varargin)

% Loads data from various formats, saves to 

% Optional args: filenames, directory, formats, saveto

p = inputParser;
addParameter(p, 'type', []);
addParameter(p, 'filenames', []);
addParameter(p, 'directory', []);
addParameter(p, 'format', []);
addParameter(p, 'saveto', []);
parse(p, varargin{:})

% Use UI to get missing arguments

if isempty(p.Results.type)
    dataTypes = {'Eye data', 'Event logs'};
    typeIdx = listdlg('PromptString', 'Select the format of the eye data files:',...
        'ListString', dataTypes,...
        'ListSize', [500 500]);
    dataType = dataTypes{typeIdx};
else
    dataType = p.Results.type;
end

if isempty(p.Results.format)
    if strcmpi(dataType, dataTypes{1})
        formatOptions = {'Tobii Excel files'
            'EXF files from The Eye Tribe'};
    elseif strcmpi(dataType, dataTypes{2})
        formatOptions = {'Noldus Excel files'
            'Presentation .log files'
            'E-DataAid Excel files'};
    else
        error('Unknown format ''%s''', p.Results.format)
    end
    formatIdx = listdlg('PromptString', sprintf('Select the format of the %s', dataType),...
        'ListString', formatOptions,...
        'ListSize', [500 500]);
    dataFormat = formatOptions{formatIdx};
else
    dataFormat = p.Results.format;
end

if isempty(p.Results.directory) || isempty(p.Results.filenames)
    uiwait(msgbox(sprintf('Select the %s to format', dataType)));
    [dataFiles, dataDirectory] = uigetfile('./*.*', ...
        sprintf('Select the %s', dataFormat),...
        'MultiSelect','on');
else
    dataFiles = p.Results.filenames;
    dataDirectory = p.Results.directory;
end
dataFiles = cellstr(dataFiles);

if numel(dataFormat) == 1 % Potentially many different formats
    dataFormat = repmat(dataFormat, numel(dataFiles, 1));
end

data = [];
for fileIdx = 1:numel(dataFiles)
    data(fileIdx) = loadrawdata(dataFiles{fileIdx},...
        dataDirectory,...
        dataFormat{fileIdx});
end

if isempty(p.Results.saveto)
    answer = questdlg(sprintf('Save formatted %s?', dataType),...
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
    for currEYE = data
        save([saveDirectory '\' currEYE.name '.eyedata'], 'currEYE');
    end
end