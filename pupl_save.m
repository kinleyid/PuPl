function pupl_save(varargin)

% Save eye data or event logs
%   Inputs
% type--data type: see getextfromdatatype for more info
% data--struct array of eye dats to be saved
% directory--directory to save to
% name--char description of data being saved; not necessary

p = inputParser;
addParameter(p, 'type', [])
addParameter(p, 'data', [])
addParameter(p, 'directory', [])
parse(p, varargin{:});

if isempty(p.Results.type)
    dataTypeOptions = {
        'eye data'
        'event logs'};
    dataType = dataTypeOptions{listdlg('PromptString', 'Data type',...
        'ListString', dataTypeOptions)};
else
    dataType = p.Results.type;
end
if strcmp(dataType, 'eye data')
    fileExt = '.eyedata';
elseif strcmp(dataType, 'event logs')
    fileExt = '.eventlog';
end

if isempty(p.Results.data)
    uiwait(msgbox('No data to save'));
    return
else
    structArray = p.Results.data;
end

if isempty(p.Results.directory)
    saveDirectory = uigetdir('.',...
        sprintf('Save %s', dataType));
    if saveDirectory == 0
        return
    end
else
    saveDirectory = p.Results.directory;
end

for data = structArray(:)'
    save(strcat(saveDirectory, '\\', data.name, fileExt), 'data');
end

end