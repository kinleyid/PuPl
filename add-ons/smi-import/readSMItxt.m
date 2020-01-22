% Based on dpg.unipd.it/sites/dpg.unipd.it/files/BeGaze2.pdf

function out = readSMItxt(fullpath)

%% Read raw

raw = readdelim2cell(fullpath, '\t', '##');
cols = lower(raw(1, :));
contents = raw(2:end, :);

timestamps = cellstr2num(contents(:, strcmp(cols, 'time')));
timestamps = timestamps - timestamps(1);

srate = estimatesrate(timestamps);
while srate == 0
    timestamps = timestamps / 1000;
    srate = estimatesrate(timestamps);
end

samples = contents(strcmp('SMP', contents(:, strcmp(cols, 'type'))), :);

units = [];

%% Get diameter

urdiam = [];
for fields = {
        'left'  'right'
        'l'     'r'}
    sideidx = strcontains(cols, sprintf('%s dia', fields{2}));
    if ~any(sideidx)
        continue
    else
        sideidx = find(sideidx);
        % Get units
        token = regexp(cols{sideidx(1)}, '.+\[(.+)\]', 'tokens');
        diamunits = token{1}{1};
        currsamples = samples(:, sideidx);
        currdata = mean(reshape(cellstr2num(currsamples), size(currsamples)), 2);
        urdiam.(fields{1}) = currdata;
    end
end

units.diam.left = {'diameter' diamunits 'absolute'};
units.diam.right = units.diam.left;

%% Get gaze

urgaze = [];
for ax = {'x' 'y'}
    for fields = {
            'left'  'right'
            'l'     'r'}
        curridx = find(strcontains(cols, sprintf('%s por %s', fields{2}, ax{:})));
        token = regexp(cols{curridx(1)}, '.+\[(.+)\]', 'tokens');
        gazeunits = token{1}{1};
        if ~any(curridx)
            continue
        end
        urgaze.(ax{:}).(fields{1}) = cellstr2num(samples(:, curridx));
    end
end

units.gaze.x = {'gaze' gazeunits 'unknown relative position'};
units.gaze.y = units.gaze.x;

%% Get events

triggers = samples(:, strcmp(cols, 'trigger'));
onsets = [false; diff(cellstr2num(triggers)) > 0];
latencies = find(onsets);

event = struct(...
    'type', triggers(onsets),...
    'time', num2cell(timestamps(onsets)),...
    'latency', num2cell(latencies),...
    'rt', repmat({NaN}, size(latencies)))';
[~, I] = sort([event.time]);
event = event(I);

%% Generate final output

out = struct(...
    'urdiam', urdiam,...
    'srate', srate,...
    'urgaze', urgaze,...
    'event', event,...
    'units', units);

end