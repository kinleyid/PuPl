
function outStruct = loadtobiipro(fullpath, type)

% Based on https://www.tobiipro.com/siteassets/tobii-pro/user-manuals/tobii-pro-studio-user-manual.pdf

%% Read raw file

switch type
    case 'xls'
        [~ , ~, r] = xlsread(fullpath);
    case 'tab'
        r = readdelim2cell(fullpath, '\t');
end

cols = lower(r(1, :));
contents = r(2:end, :);

%% Get recording timestamps (should start at 0 and be in seconds)

timestamps = str2double(contents(:, strcontains(cols, 'recordingtimestamp')));

% Set initial timestamp to 0
timestamps = timestamps - timestamps(1);

% Get times in seconds and estimate sample rate
srate = estimatesrate(timestamps);
while srate == 0
    timestamps = timestamps / 1000;
    srate = estimatesrate(timestamps);
end

%% Get events

% Get event types, timestamps, and latencies
eventcols = strcontains(cols, 'event') & ...
    ~strcontains(cols, 'gaze'); % Columns with both "gaze" and "event" are saccades, fixations, etc.
eventtypes = cellfun(@num2str, contents(:, eventcols), 'UniformOutput', false);
eventtypes = num2cell(eventtypes, 2);
eventtypes = cellfun(@(x) [x{:}], eventtypes, 'UniformOutput', false);
nonemptyidx = ~cellfun(@isempty, eventtypes);
latencies = find(nonemptyidx);

event = struct(...
    'type', eventtypes(nonemptyidx),...
    'time', num2cell(timestamps(nonemptyidx)),...
    'latency', num2cell(latencies),...
    'rt', repmat({NaN}, size(latencies)))';
[~, I] = sort([event.time]);
event = event(I);

%% Get diameter measuments

urdiam = [];
for field = {'left' 'right'}
    urdiam.(field{:}) = str2double(...
        empty2nan(...
            contents(:,...
                strcontains(cols, 'pupil') &...
                strcontains(cols, field{:}))))';
end

%% Get gaze measurements

urgaze = [];
gazeidx = strcontains(cols, 'gazepoint') &...
    ~strcontains(cols, 'ascs(mm)'); % Get gaze point in millimeters
for ax = {'x' 'y'}
    for side = {'left' 'right'}
        urgaze.(ax{:}).(side{:}) = str2double(...
            empty2nan(...
                contents(:, gazeidx...
                    & strcontains(cols, ax{:})...
                    & strcontains(cols, side{:}))))';
    end
end

%% Get eye coordinates

coords = [];
posidx = strcontains(cols, 'eyepos') &...
    ~strcontains(cols, 'ascs(mm)'); % Get gaze point in millimeters
for ax = {'x' 'y' 'z'}
    for side = {'left' 'right'}
        coords.(side{:}).(ax{:}) = str2double(...
                empty2nan(...
                    contents(:, posidx...
                        & strcontains(cols, ax{:})...
                        & strcontains(cols, side{:}))))';
    end
end

%% Generate final output

outStruct = struct(...
    'urdiam', urdiam,...
    'srate', srate,...
    'urgaze', urgaze,...
    'event', event,...
    'coords', coords);

end

function in = empty2nan(in)

in(cellfun(@isempty, in)) = {NaN};

end