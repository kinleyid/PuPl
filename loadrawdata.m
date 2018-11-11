function outStruct = loadrawdata(fileName,fileDirectory,fileFormat)

% EYE DATA
if strcmpi(fileFormat,'Tobii Excel files')
    fprintf(['Loading eye data from ' fileName ':\n'])
    fprintf('Reading excel file...')
    [~ , ~, R] = xlsread([fileDirectory '\' fileName]);
    fprintf('converting to usable table...')
    fprintf('creating EYE struct...')
    outStruct = [];
    [~, Name] = fileparts(fileName);
    outStruct.name = Name;
    RecordingTimestamps = cell2mat(R(2:end, strcmp(R(1,:), 'RecordingTimestamp')));
    outStruct.srate = round((length(RecordingTimestamps))/((max(RecordingTimestamps) - min(RecordingTimestamps))/1000));
    outStruct.data.left = cellfun(@ProcessBadCells, R(2:end,strcmp(R(1,:),'PupilLeft')));
    outStruct.data.right = cellfun(@ProcessBadCells, R(2:end,strcmp(R(1,:),'PupilRight')));
    outStruct.urData = outStruct.data;
    Events = [];
    Times = {};
    for EventType = {'KeyPressEvent' 'MouseEvent' 'StudioEvent' 'ExternalEvent'}
        CurrEvents = R(2:end, strcmp(R(1, :), EventType{:}));
        Events = [Events; CurrEvents(~cellfun(@isempty, CurrEvents))];
        Times = [Times; num2cell(RecordingTimestamps(~cellfun(@isempty,CurrEvents)))];
    end
    outStruct.event.type = [];
    outStruct.event.time = [];
    [outStruct.event(1:length(Events)).type] = Events{:};
    [outStruct.event(1:length(Times)).time] = Times{:};
    outStruct.event = ArrangeStructByField(outStruct.event,'time');
    fprintf('done.\n');
else % Event logs
    if strcmp(EventLogFormat,'Noldus Excel files')
        [~,~,R] = xlsread([EventLogPath '\' EventLogFile]);
        EventNames = R(2:end,strcmp(R(1,:),'Behavior'));
        ModifierIdx = find(~cellfun(@isempty,(regexp(R(1,:),'Modifier*'))));
        for i = 1:length(ModifierIdx)
            EventNames = strcat(EventNames,R(2:end,ModifierIdx(i)));
        end
        EventNames = strcat(EventNames,R(2:end,strcmp(R(1,:),'Event_Type')));
        OutTimes = 1000*cell2mat(R(2:end,strcmp(R(1,:),'Time_Relative_sf')));
        OutTypes = EventNames;
    elseif strcmp(EventLogFormat,'E-DataAid Excel files')
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
    outStruct = [];
    outStruct.event(length(OutTypes)).type = [];
    outStruct.event(length(OutTimes)).time = [];
    [outStruct.event(1:length(OutTypes)).type] = OutTypes{:};
    [outStruct.event(1:length(OutTimes)).time] = OutTimes{:};
    outStruct.event = ArrangeStructByField(outStruct.event,'time');
end

function Out = ProcessBadCells(In)

if isempty(In)
    Out = NaN;
else
    Out = In;
end
