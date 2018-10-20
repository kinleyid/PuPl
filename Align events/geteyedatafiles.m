function [eyeDataFiles,eyeDataPath,eyeDataFormat] = geteyedatafiles

uiwait(msgbox('Select the raw pupillometry data'));
fileFormatOptions = {'Excel files from Tobii' 'EXF files from The Eye Tribe'};
Idx = listdlg('PromptString','File type:',...
              'ListString',fileFormatOptions);
eyeDataFormat= fileFormatOptions{Idx};

if strcmp(eyeDataFormat,'Excel files from Tobii')
    [eyeDataFiles,eyeDataPath] = uigetfile('..\..\..\*.*','Select the excel files from Tobii','MultiSelect','on');
elseif strcmp(EYEFormat,'XDF files from The Eye Tribe')
    [eyeDataFiles,eyeDataPath] = uigetfile('..\..\..\*.*','Select the XDF files from The Eye Tribe','MultiSelect','on');
end
eyeDataFiles = cellstr(eyeDataFiles);