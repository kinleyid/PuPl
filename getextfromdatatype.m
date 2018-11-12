function [fileExtension, dataType] = getextfromdatatype(dataType)

% This function is a code smell

fileTypeOptions = {
    'eye data'
    'event logs'};

if isempty(dataType)
    dataType = fileTypes(listdlg('PromptString', 'Data type'),...
        'ListString', fileTypes);
end

if strcmpi(dataType, 'eye data')
    fileExtension = '.eyedata';
elseif strcmpi(dataType, 'event logs')
    fileExtension = '.eventlog';
else
    error('Unrecognized file type %s--options are:\n%s',...
        fileType,...
        sprintf('[%s]\n', fileTypeOptions{:}));
end

end