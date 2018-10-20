function EventLog = LoadRawEventLog(EventLogFile,EventLogPath,EventLogFormat)

fprintf('Loading event log...')
if strcmp(EventLogFormat,'Excel files from Noldus')
    [~,~,R] = xlsread([EventLogPath '\' EventLogFile]);
    EventNames = R(2:end,strcmp(R(1,:),'Behavior'));
    ModifierIdx = find(~cellfun(@isempty,(regexp(R(1,:),'Modifier*'))));
    for i = 1:length(ModifierIdx)
        EventNames = strcat(EventNames,R(2:end,ModifierIdx(i)));
    end
    EventNames = strcat(EventNames,R(2:end,strcmp(R(1,:),'Event_Type')));
    OutTimes = 1000*cell2mat(R(2:end,strcmp(R(1,:),'Time_Relative_sf')));
    OutTypes = EventNames;
elseif strcmp(EventLogFormat,'.eventlog file from this analysis code')
elseif strcmp(EventLogFormat,'Excel files from E-DataAid')
    [~,~,EventLog] = xlsread([EventLogPath '\' EventLogFile]);
    Times = cell2mat(EventLog(3:end,:));
    EventTypes = EventLog(2,:);
    Size = size(Times);
    [Times,Idx] = sort(Times(:));
    OutTimes = zeros(length(Times),1);
    OutTypes = cell(length(Times),1);
    for i = 1:length(Times)
        OutTimes(i) = Times(i);
        [~,Sub] = ind2sub(Size,Idx(i));
        OutTypes(i) = EventTypes(Sub);
    end
    OutTypes(isnan(OutTimes)) = [];
    OutTimes(isnan(OutTimes)) = [];
end

EventLog = [];
EventLog.event(length(OutTypes)).type = [];
EventLog.event(length(OutTimes)).time = [];

OutTimes = num2cell(OutTimes);

[EventLog.event.type] = OutTypes{:};
[EventLog.event.time] = OutTimes{:};
fprintf('done.\n');