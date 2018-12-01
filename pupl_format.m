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

structArray = [];

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

if isempty(p.Results.format)
    if strcmpi(dataType, 'eye data')
        formatOptions = {
            'Tobii Excel files'
            'XDF files'
        };
    elseif strcmpi(dataType, 'event logs')
        formatOptions = {
            'Noldus Excel files'
            'Presentation log files'
            'XDF files'
            'E-DataAid Excel files'
        };
    end
    dataFormat = formatOptions(listdlg('PromptString', 'File format',...
        'ListString', formatOptions));
    if isempty(dataFormat)
        return
    end
else
    dataFormat = p.Results.format;
end
dataFormat = char(dataFormat);

if isempty(p.Results.directory) || isempty(p.Results.filenames)
    % uiwait(msgbox(sprintf('Select the %s to format', dataFormat)));
    [dataFiles, dataDirectory] = uigetfile('./*.*', ...
        sprintf('Select the %s', dataFormat),...
            'MultiSelect','on');
    if dataFiles == 0
        return
    end
else
    dataFiles = p.Results.filenames;
    dataDirectory = p.Results.directory;
end
dataFiles = cellstr(dataFiles);

structArray = cellfun(@(file) pupl_readraw(dataType, file, dataDirectory, dataFormat), dataFiles);

end

