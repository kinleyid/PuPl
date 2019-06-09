
function outStruct = loadtobiiexcel(fullpath)

outStruct = struct([]);

[~, name] = fileparts(fullpath);
fprintf('Importing %s\n', name)
currStruct = struct(...
    'name', name,...
    'src', fullpath);
[~ , ~, R] = xlsread(fullpath);

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

events = cellfun(@num2str, events, 'un', 0);
event = struct(...
    'type', events(:)',...
    'time', times(:)');
[~, I] = sort([event.time]);
event = event(I);

timestamps = cell2mat(timestamps);
srate = round((numel(timestamps) - 1)/((max(timestamps) - min(timestamps))));

diam = struct(...
    'left', {R(2:end, strcmp(R(1, :), 'PupilLeft'))},...
    'right', {R(2:end, strcmp(R(1, :), 'PupilRight'))});
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

currStruct.event = event;

outStruct = pupl_check(outStruct);

fprintf('done\n')

end