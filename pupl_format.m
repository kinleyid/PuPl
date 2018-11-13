function structArray = pupl_format(varargin)

% Format eye data or event logs
%   Inputs
% type--'eye data' or 'event logs'
% filenames--cell array
% directory--char
% format--format of data

p = inputParser;
addParameter(p, 'type', [])
addParameter(p, 'filenames', [])
addParameter(p, 'directory', [])
addParameter(p, 'format', [])
parse(p, varargin{:});

if isempty(p.Results.type)
    dataTypeOptions = {
        'eye data'
        'event logs'};
    dataType = dataTypeOptions(listdlg('PromptString', 'Data type'),...
        'ListString', dataTypeOptions);
else
    dataType = p.Results.type;
end

if isempty(p.Results.format)
    if strcmpi(dataType, 'eye data')
        formatOptions = {
            'Tobii Excel files'
            'EXF files from The Eye Tribe'};
    elseif strcmpi(dataType, 'event logs')
        formatOptions = {
            'Noldus Excel files'
            'Presentation .log files'
            'E-DataAid Excel files'};
    end
    dataFormat = listdlg('PromptString', 'File format',...
        'ListString', formatOptions);
else
    dataFormat = p.Results.format;
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

end