
function outStruct = loadtobii(fullpath, type)

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

timestamps = cellstr2num(contents(:, strcontains(cols, 'recording')...
    & strcontains(cols, 'timestamp')));

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
    ~strcontains(cols, 'gaze'); % Columns with "gaze" and "event" are saccades, fixations, etc.
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

pupilidx = strcontains(cols, 'pupil');
if nnz(pupilidx) > 2
    if mod(nnz(pupilidx), 2) == 1 && any(strcontains(cols(pupilidx), 'glasses'))
        pupilidx = pupilidx & ...
            ~strcontains(cols, 'glasses');
    elseif strcontains(cols(pupilidx), 'area') || strcontains(cols(pupilidx), 'size')
        pupilidx = pupilidx & ...
            strcontains(cols, 'diam'); % We only want diameter
    end
end
urdiam = [];
for field = {'left' 'right'}
    urdiam.(field{:}) = cellstr2num(...
        empty2nan(...
            contents(:,...
                pupilidx &...
                strcontains(cols, field{:}))))';
end

%% Get gaze measurements

urgaze = [];
gazeidx = strcontains(cols, 'gaze') &...
    ~strcontains(cols, 'average'); % Don't use the averages
if nnz(gazeidx) > 4
    if any(strcontains(cols(gazeidx), '3')) % 3-dimensional coords?
        gazeidx = gazeidx &...
            strcontains(cols, '2'); % We only want 2d coords
    elseif any(strcontains(cols(gazeidx), 'mm')) % Multiple units?
        gazeidx = gazeidx &...
            strcontains(cols, 'mm'); % Get gaze position in millimetres rather than pixes
    end
end
for ax = {'x' 'y'}
    for side = {'left' 'right'}
        urgaze.(ax{:}).(side{:}) = cellstr2num(...
            empty2nan(...
                contents(:, gazeidx...
                    & strcontains(cols, ax{:})...
                    & strcontains(cols, side{:}))))';
    end
end

%% Generate final output

outStruct = struct(...
    'urdiam', urdiam,...
    'srate', srate,...
    'urgaze', urgaze,...
    'event', event);

end

function in = empty2nan(in)

in(cellfun(@isempty, in)) = {NaN};

end