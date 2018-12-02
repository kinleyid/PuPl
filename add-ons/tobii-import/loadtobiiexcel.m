function outStructArray = loadtobiiexcel(varargin)

outStructArray = [];

p = inputParser;
addParameter(p, 'filename', [])
addParameter(p, 'directory', '.')
addParameter(p, 'as', 'eye data')
parse(p, varargin{:});

directory = p.Results.directory;

if isempty(p.Results.filename)
    [filename, directory] = uigetfile([directory '\\*.*'],...
        'MultiSelect', 'on');
    if isnumeric(filename)
        return
    end
else
    filename = p.Results.filename;
end
filename = cellstr(filename);

for fileIdx = 1:numel(filename)

    [~, name] = fileparts(filename{fileIdx});
    currStruct = struct('name', name);
    [~ , ~, R] = xlsread([directory '\\' filename{fileIdx}]);

    timestamps = cell2mat(R(2:end, strcmp(R(1, :), 'RecordingTimestamp')));
    
    [events, times] = deal({});
    for eventType = {'KeyPressEvent' 'MouseEvent' 'StudioEvent' 'ExternalEvent'}
        currEvents = R(2:end, strcmp(R(1, :), eventType{:}));
        events = cat(1, events, currEvents(~cellfun(@isempty, currEvents)));
        times = cat(1, times, timestamps(~cellfun(@isempty, currEvents)));
    end
    event = struct(...
        'type', events,...
        'time', times);
    [~, I] = sort([event.time]);
    event = event(I);
    
    if strcmp(p.Results.as, 'eye data')
    
        srate = round((length(timestamps))/((max(timestamps) - min(timestamps))/1000));

        data = struct(...
            'left', R(2:end, strcmp(R(1, :), 'PupilLeft')),...
            'right', R(2:end, strcmp(R(1, :), 'PupilRight')));
        for field = reshape(fieldnames(data), 1, [])
            data.(field{:})(cellfun(@isempty, data.(field{:}))) = {NaN};
            data.(field{:}) = reshape(cell2mat(data.(field{:})), 1, []);
        end
        
        latencies = num2cell([event.time]/srate + 1);
        [event.latency] = latencies{:};
        
        gaze = [];
        
        currStruct.data = data;
        currStruct.urData = data;
        currStruct.srate = srate;
        currStruct.gaze = gaze;
        currStruct.epoch = [];
        currStruct.bin = [];
        currStruct.cond = [];
        currStruct.isBlink = false(size(data.left));
        
    end
    
    currStruct.event = event;
    
    outStructArray = [outStructArray currStruct];
    
end