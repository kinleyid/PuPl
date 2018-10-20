function [EventLogFiles,EventLogPath,EventLogFormat] = GetRawEventLogFiles

EventLogFormats = {'Excel files from Noldus' '.eventlog file from this analysis code' '.log files from Presentation'};
Idx = listdlg('PromptString','Event log file format:',...
                           'ListString',EventLogFormats);
EventLogFormat = EventLogFormats(Idx);

if strcmp(EventLogFormat,'Excel files from Noldus')
    [EventLogFiles,EventLogPath] = uigetfile('..\..\..\*.*','Select the Excel files from Noldus','MultiSelect','on');
elseif strcmp(EventLogFormat,'.log files from Presentation')
    [EventLogFiles,EventLogPath] = uigetfile('..\..\..\*.*','Select the .log files from Presentation','MultiSelect','on');
end
EventLogFiles = cellstr(EventLogFiles);