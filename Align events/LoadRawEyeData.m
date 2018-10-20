function EYE = LoadRawEyeData(EyeFile,EyePath,EyeFormat)


if strcmp(EyeFormat,'Excel files from Tobii')
    fprintf(['Loading eye data from ' EyeFile ':\n'])
    fprintf('Reading excel file...')
    [~,~,R] = xlsread([EyePath '\' EyeFile]);
    fprintf('converting to usable table...')
    fprintf('creating EYE struct...')
    EYE = [];
    [~,Name] = fileparts(EyeFile);
    EYE.name = Name;
    
    RecordingTimestamps = cell2mat(R(2:end,strcmp(R(1,:),'RecordingTimestamp')));
    EYE.srate = round((length(RecordingTimestamps))/((max(RecordingTimestamps) - min(RecordingTimestamps))/1000));
    EYE.data.left = cellfun(@ProcessBadCells, R(2:end,strcmp(R(1,:),'PupilLeft')));
    EYE.data.right = cellfun(@ProcessBadCells, R(2:end,strcmp(R(1,:),'PupilRight')));
    Events = [];
    Times = {};
    for EventType = {'KeyPressEvent' 'MouseEvent' 'StudioEvent' 'ExternalEvent'}
        CurrEvents = R(2:end,strcmp(R(1,:),EventType{:}));
        Events = [Events; CurrEvents(~cellfun(@isempty,CurrEvents))];
        Times = [Times; num2cell(RecordingTimestamps(~cellfun(@isempty,CurrEvents)))];
    end
    EYE.event.type = [];
    EYE.event.time = [];
    [EYE.event(1:length(Events)).type] = Events{:};
    [EYE.event(1:length(Times)).time] = Times{:};
    EYE.event = ArrangeStructByField(EYE.event,'time');
    fprintf('done.\n');
end

function Out = ProcessBadCells(In)

if isempty(In)
    Out = NaN;
else
    Out = In;
end