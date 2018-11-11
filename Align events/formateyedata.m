function EYE = formateyedata(varargin)

% Loads data from various formats, saves to 

% Optional args: filenames, directory, formats, saveto

p = inputParser;
addParameter(p, 'filenames', []);
addParameter(p, 'directory', []);
addParameter(p, 'format', []);
addParameter(p, 'saveto', []);
parse(p, varargin{:})

% Use UI to get missing arguments

if isempty(p.Results.format)
    eyeDataFormats = {'Tobii Excel files' 'EXF files from The Eye Tribe'};
    iFormat = listdlg('PromptString', 'Select the format of the eye data files:',...
        'ListString', eyeDataFormats,...
        'ListSize', [500 500]);
    eyeDataFormat = eyeDataFormats{iFormat};
else
    eyeDataFormat = p.Results.format;
end

if isempty(p.Results.directory) || isempty(p.Results.filenames)
    uiwait(msgbox('Select the eye data to format'));
    [eyeFiles, eyeDirectory] = uigetfile('./*.*', ...
        sprintf('Select the %s', eyeDataFormat),...
        'MultiSelect','on');
else
    eyeFiles = p.Results.filenames;
    eyeDirectory = p.Results.directory;
end
eyeFiles = cellstr(eyeFiles);

if numel(eyeDataFormat) == 1 % Potentially many different formats
    eyeDataFormat = repmat(eyeDataFormat, numel(eyeFiles, 1));
end

for fileIdx = 1:numel(eyeFiles)
    EYE = loadraweyedata(eyeFiles{fileIdx},...
        eyeDirectory,...
        eyeDataFormat{fileIdx});
end

if isempty(p.Results.saveto)
    answer = questdlg('Save formatted eye files?',...
        'Save formatted eye files?',...
        'Yes', 'No', 'Yes');
    if strcmp(answer, 'Yes')
        saveDirectory = uigetdir(eyeDirectory,...
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
    for dataIdx = 1:numel(EYE)
        currData = EYE(dataIdx);
        save([SaveTo '\' currData.name '.eyedata'], 'currData');
    end
end