function AlignEvents

[EyeFiles,EyePath,EyeFormat] = GetRawEyeFiles;

AttachEventLogEvents = questdlg('Attach events from event logs?', ...
    'Attach events from event logs?', ...
    'Yes','No','Merge event logs first','Yes');

if strcmp(AttachEventLogEvents,'Merge event logs first')
    MergeEventLogs;
elseif strcmp(AttachEventLogEvents,'No')
    uiwait(msgbox('Select a folder to save the formatted eye data to.','','modal'));
    SaveTo = uigetdir([EYEPath '\..'],'Where will the formatted eye data be saved?');
    for Idx = 1:length(EyeFiles)
        EYE = LoadRawEyeData(EyeFiles{Idx},EyePath,EyeFormat);
        EYE = GetEYESpecs(EYE);
        save([SaveTo '\' EYE.name '.eyedata'],'EYE');
    end
    return
end

[EventLogFiles,EventLogPath,EventLogFormat] = GetRawEventLogFiles;

[EyeFiles,EventLogFiles] = FixFileCorrespondence(EyeFiles,EventLogFiles);

Idx = listdlg('PromptString',{'Select an eye data file to use as a template'},...
    'SelectionMode','single',...
    'ListSize',[500,300],...
    'ListString',EyeFiles);

EYE = LoadRawEyeData(EyeFiles{Idx},EyePath,EyeFormat);

Idx = listdlg('PromptString',{'Select an event log file to use as a template' '(Does not have to correspond to eye data file)'},...
    'SelectionMode','single',...
    'ListSize',[500,300],...
    'ListString',EventLogFiles);
EventLog = LoadRawEventLog(EventLogFiles{Idx},EventLogPath,EventLogFormat);
[EYEEventBins,EventLogEventBins] = GetEventCorrespondence(EYE,EventLog,'Do not show occurrence counts');

[EventLogEventsToAttach,NamesToUse] = GetEventsToAttach(EventLog);
uiwait(msgbox('Select a folder to save the aligned eye data to.','','modal'));
SaveTo = uigetdir('..\..\..','Where will the aligned eye data be saved?');

for i = 1:length(EyeFiles)
    EYE = LoadRawEyeData(EyeFiles{i},EyePath,EyeFormat);
    EYE = GetEYESpecs(EYE);
    EventLog = LoadRawEventLog(EventLogFiles{i},EventLogPath,EventLogFormat);
    Params = FindOffset(EYE,EventLog,EYEEventBins,EventLogEventBins);
    EYE = AttachEvents(EYE,EventLog,Params,EventLogEventsToAttach,NamesToUse);
    EYE = AddLatencies(EYE);
    fprintf('Saving [%s] to [%s]',EYE.name,SaveTo)
    save([SaveTo '\' EYE.name '.mat'],'EYE');
end