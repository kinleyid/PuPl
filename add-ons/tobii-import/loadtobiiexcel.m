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
    fprintf('Importing %s\n', name)
    currStruct = struct('name', name);
    fprintf('\tReading Excel file...')
    [~ , ~, R] = xlsread([directory '\\' filename{fileIdx}]);
    fprintf('done\n')
    
    timestamps = R(2:end, strcmp(R(1, :), 'RecordingTimestamp'));
    timestamps = cellfun(@(x) x/1000, timestamps, 'un', 0); % Get time in seconds
    
    [events, times] = deal({});
    eventCols = ~cellfun(@isempty, regexp(R(1, :), '[eE]vent'))...
        & ~strcmpi(R(1, :), 'GazeEventType')...
        & ~strcmpi(R(1, :), 'GazeEventDuration');
    for colIdx = find(eventCols)
        currEvents = R(2:end, colIdx);
        events = cat(1, events, currEvents(~cellfun(@isempty, currEvents)));
        times = cat(1, times, timestamps(~cellfun(@isempty, currEvents)));
    end
    fprintf('\tFound %d events\n', numel(events))
    event = struct(...
        'type', events(:)',...
        'time', times(:)');
    [~, I] = sort([event.time]);
    event = event(I);
    
    if strcmp(p.Results.as, 'eye data')
        timestamps = cell2mat(timestamps);
        srate = round((length(timestamps))/((max(timestamps) - min(timestamps))));
        fprintf('\tEstimated sample rate: %d Hz\n', srate);

        diam = struct(...
            'left', {R(2:end, strcmp(R(1, :), 'PupilLeft'))},...
            'right', {R(2:end, strcmp(R(1, :), 'PupilRight'))});
        fprintf('\tSetting empty pupil diameter measurements to NaN\n');
        for field = {'left' 'right'}
            diam.(field{:})(cellfun(@isempty, diam.(field{:}))) = {NaN};
            diam.(field{:}) = reshape(cell2mat(diam.(field{:})), 1, []);
        end
        
        urDiam = [];
        urDiam.left.x = diam.left;
        urDiam.left.y = diam.left;
        urDiam.right.x = diam.right;
        urDiam.right.y = diam.right;
        
        [~, latencies] = min(abs(bsxfun(@minus,...
            reshape(timestamps,...
                [], 1),...
            reshape([event.time],...
                1, []))));
        latencies = num2cell(latencies);
        [event.latency] = latencies{:};
        
        urGaze = [];
        gazeIdx = ~cellfun(@isempty, regexp(R(1, :), 'Gaze.*mm'))...
            & cellfun(@isempty, regexp(R(1, :), 'Average'));
        fprintf('\tSetting empty gaze measurements to NaN\n');
        for ax = {'x' 'y'}
            for side = {'left' 'right'}
                urGaze.(ax{:}).(side{:}) = R(2:end,...
                        gazeIdx...
                        & ~cellfun(@isempty, regexp(lower(R(1, :)), ax{:}))...
                        & ~cellfun(@isempty, regexp(lower(R(1, :)), side{:})));
                urGaze.(ax{:}).(side{:})(cellfun(@isempty, urGaze.(ax{:}).(side{:}))) = {NaN};
                urGaze.(ax{:}).(side{:}) = reshape(cell2mat(urGaze.(ax{:}).(side{:})), 1, []);
            end
        end
        
        gaze = [];
        gaze.x = mean([
            urGaze.x.left
            urGaze.x.right]);
        gaze.y = mean([
            urGaze.y.left
            urGaze.y.right]);
        
        currStruct.diam = diam;
        currStruct.urDiam = urDiam;
        currStruct.srate = srate;
        currStruct.gaze = gaze;
        currStruct.urGaze = urGaze;
        currStruct.epoch = [];
        currStruct.bin = [];
        currStruct.cond = [];
        currStruct.isBlink = false(size(diam.left));
        
    end
    
    currStruct.event = event;
    
    outStructArray = [outStructArray currStruct];
    
end

fprintf('done\n')

end