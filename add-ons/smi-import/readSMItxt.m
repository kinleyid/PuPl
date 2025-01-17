% Based on dpg.unipd.it/sites/dpg.unipd.it/files/BeGaze2.pdf
% and https://tsgdoc.socsci.ru.nl/images/6/6f/IViewX.pdf

function out = readSMItxt(fullpath)

fprintf('\n');

% Read raw
% NB: we cannot read delim because rows with MSG (vs SMP) will not have the standard number of columns
rawdata = fastfileread(fullpath);
% Split into lines
lines = regexp(rawdata, '.*', 'match', 'dotexceptnewline');

% Get first 2 characters
first_2_chars = regexp(rawdata, '^..', 'match', 'lineanchors', 'dotexceptnewline');
% Header is lines where first 2 chars are ##
nonheader_lines = lines(~strcmp(first_2_chars, '##'));

% Column names are first data line
colnames_line = nonheader_lines{1};
colnames = lower(regexp(colnames_line, '\t', 'split'));
% Data lines are remainder
noncolnames_lines = nonheader_lines(2:end);

% MSG lines contain "MSG"
msg_line_idx = ~cellfun(@isempty, regexp(noncolnames_lines, 'MSG', 'once'));
msg_lines = noncolnames_lines(msg_line_idx); % These will be read as events later
data_lines = noncolnames_lines(~msg_line_idx);

% With MSG lines gone, the data should be a matrix
% However, we can't read it as a matrix yet because it contains text ("SMP" indicators)
% Therefore replace them with nan
data_lines = regexprep(data_lines, 'SMP', 'nan');
% Read as matrix (ncol x nsamp, don't waste time transposing)
datamat = cell2mat(cellfun(@(x) sscanf(x, '%g'), data_lines, 'UniformOutput', false));

% Get timestamps and estimate srate
timestamps = datamat(strcmp(colnames, 'time'), :);
srate = estimatesrate(timestamps);
timestamp_divide_fac = 1;
while srate == 0
    timestamps = timestamps / 1000;
    timestamp_divide_fac = timestamp_divide_fac * 1000;
    srate = estimatesrate(timestamps);
end

% Get pupil size
mappedidx = strcontains(colnames, 'mapped'); % "mapped" measurements should be prioritized
pupil = [];
for fields = {
        'left'  'right'
        'l'     'r'}
    sideidx = ~cellfun(@isempty, regexp(colnames, sprintf('^%s ', fields{2}))) & strcontains(colnames, 'dia');
    if any(mappedidx)
        sideidx = sideidx & mappedidx;
    end
    if ~any(sideidx)
        continue
    end
    sideidx = find(sideidx);
    % Print
    fprintf('%s pupil diameter computed using column(s)\n', fields{1});
    fprintf('- "%s"\n', colnames{sideidx});
    % Get units
    token = regexp(colnames{sideidx(1)}, '.+\[(.+)\]', 'tokens');
    diamunits = token{1}{1};
    currsamples = datamat(sideidx, :);
    currdata = mean(currsamples, 1);
    pupil.(fields{1}) = currdata(:);
end

units.pupil = {'diameter' diamunits 'absolute'};

% Get gaze
poridx = strcontains(colnames, ' por '); % "por" measurements should be prioritized
rawidx = strcontains(colnames, ' raw '); % "raw" measurements used as backup
gaze = [];
for ax = {'x' 'y'}
    for fields = {
            'left'  'right'
            'l'     'r'}
        sideidx = ~cellfun(@isempty, regexp(colnames, sprintf('^%s ', fields{2})));
        axidx = strcontains(colnames, sprintf(' %s ', ax{:}));

        curridx = sideidx & axidx;
        if any(poridx)
            curridx = curridx & poridx;
        else
            curridx = curridx & rawidx;
        end
        if ~any(curridx)
            continue
        end
        curridx = find(curridx);
        % Get units
        token = regexp(colnames{curridx(1)}, '.+\[(.+)\]', 'tokens');
        gazeunits = token{1}{1};
        fprintf('%s pupil diameter computed using column "%s"\n', fields{1}, colnames{curridx});
        currdata = datamat(curridx, :);
        gaze.(ax{:}).(fields{1}) = currdata(:);
    end
end

units.gaze.x = {'x' gazeunits 'unknown relative position'};
units.gaze.y = {'y' gazeunits 'unknown relative position'};

% Get events based on MSG lines
n_msg = numel(msg_lines);
msg_events = struct(... % Container
    'name', repmat({''}, n_msg, 1),...
    'time', repmat({''}, n_msg, 1));
for msg_idx = 1:n_msg
    msg_line_components = regexp(msg_lines{msg_idx}, '\t', 'split');
    msg_events(msg_idx).name = msg_line_components{end};
    msg_events(msg_idx).time = str2num(msg_line_components{1}) / timestamp_divide_fac;
end

% Get events based on triggers
triggers = datamat(strcmp(colnames, 'trigger'), :);
onsets = [false; diff(triggers) > 0];
trigger_events = struct(...
    'name', triggers(onsets),...
    'time', num2cell(timestamps(onsets)));

% Get final events
event = [
    msg_events
    trigger_events
];
if numel(event) > 0
    [~, I] = sort([event.time]);
    event = event(I);
end

% Generate final output

out = struct(...
    'pupil', pupil,...
    'gaze', gaze,...
    'srate', srate,...
    'times', timestamps,...
    'event', event,...
    'units', units);

end
