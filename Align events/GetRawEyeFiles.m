function [EyeFiles,EyePath,EyeFormat] = GetRawEyeFiles

uiwait(msgbox('Select the raw eye data'));
EyeFormats = {'Excel files from Tobii' 'EXF files from The Eye Tribe'};
Idx = listdlg('PromptString','Eye file type:',...
                           'ListString',EyeFormats);
EyeFormat = EyeFormats{Idx};

if strcmp(EyeFormat,'Excel files from Tobii')
    [EyeFiles,EyePath] = uigetfile('..\..\..\*.*','Select the excel files from Tobii','MultiSelect','on');
elseif strcmp(EYEFormat,'XDF files from The Eye Tribe')
    [EyeFiles,EyePath] = uigetfile('..\..\..\*.*','Select the XDF files from The Eye Tribe','MultiSelect','on');
end
EyeFiles = cellstr(EyeFiles);