
function outStruct = loadtobii(fullpath, type)

% Based on:
% tobiipro.com/siteassets/tobii-pro/user-manuals/tobii-pro-studio-user-manual.pdf
% tobiipro.com/siteassets/tobii-pro/user-manuals/Tobii-Pro-Lab-User-Manual/

%% Read raw file

switch type
    case 'xls'
        [~ , ~, r] = xlsread(fullpath);
    case 'tab'
        r = readdelim2cell(fullpath, '\t');
    case 'csv'
        r = readdelim2cell(fullpath, ',');
end

cols = lower(r(1, :));
contents = r(2:end, :);

% Are we working from Tobii Studio or Tobii Pro Lab?
if any(strcontains(cols, 'adcs')) || any(strcontains(cols, 'mcs'))
    tobii = 'studio';
else
    tobii = 'pro lab';
end

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

pupil_units = {'diameter' 'mm' 'absolute'};

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

urpupil = [];
for field = {'left' 'right'}
    urpupil.(field{:}) = cellstr2num(...
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
    end
    if any(strcontains(cols(gazeidx), 'mm')) % Multiple units?
        gazeidx = gazeidx &...
            strcontains(cols, 'mm'); % Get gaze position in millimetres rather than pixes
    end
end

gaze_units = [];
switch tobii
    case 'studio'
        if any(strcontains(cols(gazeidx), 'adcspx'))
            gaze_units.x = {'x' 'px' 'from left side of screen'};
            gaze_units.y = {'y' 'px' 'from top of screen'};
        elseif any(strcontains(cols(gazeidx), 'adcsmm'))
            gaze_units.x = {'x' 'mm' 'from left side of screen'};
            gaze_units.y = {'y' 'mm' 'from bottom of screen'};
        elseif any(strcontains(cols(gazeidx), 'mcspx'))
            gaze_units.x = {'x' 'px' 'from left side of media'};
            gaze_units.y = {'y' 'px' 'from top of media'};
        end
    case 'pro lab'
        gaze_units.x = {'x' [] 'from left side of display'};
        gaze_units.y = {'y' [] 'from top of display'};
        if any(strcontains(cols(gazeidx), 'norm'))
            gaze_units.x{2} = 'normalized units';
            gaze_units.y{2} = 'normalized units';
        elseif any(strcontains(cols(gazeidx), 'mm'))
            gaze_units.x{2} = 'mm';
            gaze_units.y{2} = 'mm';
        else
            gaze_units.x{2} = 'px';
            gaze_units.y{2} = 'px';
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
    'urpupil', urpupil,...
    'srate', srate,...
    'urgaze', urgaze,...
    'event', event,...
    'units', struct(...
        'pupil', {pupil_units},...
        'gaze', {gaze_units}));

end

function in = empty2nan(in)

in(cellfun(@isempty, in)) = {NaN};

end