function AlignEvents % Rename to something denoting that UI will be used

[eyeDataFiles,eyeDataPath,eyeDataFormat] = getraweyefiles;

AttachEventLogEvents = questdlg('Attach events from event logs?', ...
    'Attach events from event logs?', ...
    'Yes','No','Merge event logs first','Yes');

if strcmp(AttachEventLogEvents,'Merge event logs first')
    % MergeEventLogs; does not yet exist
elseif strcmp(AttachEventLogEvents,'No')
    uiwait(msgbox('Select a folder to save the formatted eye data to.','','modal'));
    SaveTo = uigetdir([eyeDataPath '\..'],'Where will the formatted eye data be saved?');
    for iFile = 1:length(eyeDataFiles)
        EYE = LoadRawEyeData(eyeDataFiles{iFile},eyeDataPath,eyeDataFormat);
        EYE = GetEYESpecs(EYE);
        save([SaveTo '\' EYE.name '.eyedata'],'EYE');
    end
elseif strcmp(AttachEventLogEvents,'No')

    [EventLogFiles,EventLogPath,EventLogFormat] = GetRawEventLogFiles;

    [eyeDataFiles,EventLogFiles] = FixFileCorrespondence(eyeDataFiles,EventLogFiles);

    Idx = listdlg('PromptString',{'Select an eye data file to use as a template'},...
        'SelectionMode','single',...
        'ListSize',[500,300],...
        'ListString',eyeDataFiles);

    EYE = LoadRawEyeData(eyeDataFiles{Idx},eyeDataPath,eyeDataFormat);

    Idx = listdlg('PromptString',{'Select an event log file to use as a template' '(Does not have to correspond to eye data file)'},...
        'SelectionMode','single',...
        'ListSize',[500,300],...
        'ListString',EventLogFiles);
    EventLog = LoadRawEventLog(EventLogFiles{Idx},EventLogPath,EventLogFormat);
    [EYEEventBins,EventLogEventBins] = GetEventCorrespondence(EYE,EventLog,'Do not show occurrence counts');

    [EventLogEventsToAttach,NamesToUse] = GetEventsToAttach(EventLog);
    uiwait(msgbox('Select a folder to save the aligned eye data to.','','modal'));
    SaveTo = uigetdir('..\..\..','Where will the aligned eye data be saved?');

    for i = 1:length(eyeDataFiles)
        EYE = LoadRawEyeData(eyeDataFiles{i}, eyeDataPath, eyeDataFormat);
        EYE = GetEYESpecs(EYE);
        EventLog = LoadRawEventLog(EventLogFiles{i},EventLogPath,EventLogFormat);
        Params = FindOffset(EYE,EventLog, EYEEventBins, EventLogEventBins);
        EYE = AttachEvents(EYE,EventLog,Params,EventLogEventsToAttach,NamesToUse);
        EYE = AddLatencies(EYE);
        fprintf('Saving [%s] to [%s]',EYE.name,SaveTo)
        save([SaveTo '\' EYE.name '.mat'],'EYE');
    end
end