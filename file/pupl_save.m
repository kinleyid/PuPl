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
addParameter(p, 'batch', false)
parse(p, varargin{:});

if isempty(p.Results.type)
    dataTypeOptions = {
        'eye data'
        'event logs'};
    dataType = dataTypeOptions{listdlg('PromptString', 'Data type',...
        'ListString', dataTypeOptions)};
    if isempty(dataType)
        return
    end
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

if p.Results.batch
    path = uigetdir;
    if isnumeric(path)
        return
    else
        for dataidx = 1:numel(structArray)
            data = structArray(dataidx);
            fprintf('Saving %s\n', data.name);
            saveeyedata(fullfile(path, [data.name fileExt]));
        end
    end
else
    path = '';
    for dataidx = 1:numel(structArray)
        data = structArray(dataidx);
        [file,path] = uiputfile(sprintf('%s', path, data.name, fileExt),...
            sprintf('Save %s', data.name));
        if file == 0
            if dataidx > 1
                fprintf('Done\n');
            end
            return
        end
        [~, file] = fileparts(file);
        fprintf('Saving %s\n', data.name);
        saveeyedata(fullfile(path, [file fileExt]));
    end
end

fprintf('Done\n');

end