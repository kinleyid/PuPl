
% Based on
% https://sr-research.jp/support/EyeLink%201000%20User%20Manual%201.5.0.pdf,
% section 4.9

function EYE = readeyelinkASC(fullpath)

EYE = [];

%% Read raw

printprog('setmax', 12)
printprog(1)
rawdata = fastfileread(fullpath);
printprog(2)
% Get data lines without empty lines
lines = regexp(rawdata, '.*', 'match', 'dotexceptnewline');
printprog(3)
% Get first characters of lines, ignoring empty lines
tokens = regexp(rawdata, '^.', 'match', 'lineanchors', 'dotexceptnewline');
printprog(4)

issample = ismember([tokens{:}], '123456789'); % Lines beginning with a number are data samples
printprog(5)
samples = lines(issample); % Data sample lines
infolines = lines(~issample); % All other lines contain metadata/events
printprog(6)
firstwords = cellfun(@(x) sscanf(x, '%s', 1), infolines, 'UniformOutput', false); % Other lines are identified by their first words
printprog(7)

%% Find data

samples = regexprep(samples, '\s\.\s', ' nan '); % Missing data are dots, replace with space-padded nan
printprog(8)
datamat = cell2mat(cellfun(@(x) sscanf(x, '%g'), samples, 'UniformOutput', false));
printprog(9)

% Find an info line beginning with "samples"
sampleinfo = lower(regexp(infolines{find(strcontains(lower(firstwords), 'samples'), 1)}, '\t', 'split'));
printprog(10)
for ii = 1:numel(sampleinfo)
    switch sampleinfo{ii}
        case 'gaze'
            neyes = nnz(ismember(sampleinfo([ii+1 ii+2]), {'left' 'right'}));
            if neyes == 1
                whicheye = lower(sampleinfo{ii+1});
            end
        case 'rate'
            srate = sscanf(sampleinfo{ii+1}, '%g', 1);
            srate = round(srate);
        otherwise
            continue
    end
end

if neyes == 1
    fields = {
        {'gaze' 'x' whicheye}
        {'gaze' 'y' whicheye}
        {'pupil' whicheye}
    };
else
    fields = {
        {'gaze' 'x' 'left'}
        {'gaze' 'y' 'left'}
        {'pupil' 'left'}
        {'gaze' 'x' 'right'}
        {'gaze' 'y' 'right'}
        {'pupil' 'right'}
    };
end

% Assign samples
for ii = 1:numel(fields)
    EYE = setfield(EYE, fields{ii}{:}, datamat(ii+1, :));
end

%% Find events

printprog(11)
eventlines = infolines(strcontains(lower(firstwords), 'msg'));
event_times = nan(size(eventlines));
event_types = cell(size(eventlines));
for ii = 1:numel(eventlines)
    curreventinfo = regexp(eventlines{ii}, '\t', 'split');
    curreventinfo = regexp(curreventinfo{2}, '\s', 'split');
    event_times(ii) = sscanf(curreventinfo{1}, '%g');
    event_types{ii} = strtrim(sprintf('%s ', curreventinfo{2:end}));
end
printprog(12)
%% Process timestamps

EYE.srate = srate;
sample_times = datamat(1, :);
EYE.t1 = sample_times(1);
[sample_times, event_times] = processtimestamps(sample_times, event_times, srate);
EYE.times = sample_times/1000   ;

%% Get units

% pupil area or diameter
pupil_line = regexp(lower(infolines(find(strcmpi(firstwords, 'pupil'), 1))), '\s', 'split');
pupil_size = pupil_line{:}{2};
pupil_units = {pupil_size 'arbitrary units' 'absolute'};

% gaze units--see section 4.4.2. in the EyeLink 1000 user manual
samples_line = regexp(lower(infolines(find(strcmpi(firstwords, 'samples'), 1))), '\s', 'split');
switch samples_line{:}{2}
    case 'gaze'
        gaze_units_x = {'x' 'px' 'from screen left'};
        gaze_units_y = {'y' 'px' 'from screen top'};
    case 'href'
        gaze_units_x = {'x' 'arbitrary units' 'from HREF origin'};
        gaze_units_y = {'y' 'arbitrary units' 'from HREF origin'};
    case 'pupil'
        gaze_units_x = {'x' 'raw coordinates' 'from camera'};
        gaze_units_y = {'y' 'raw coordinates' 'from camera'};    
end

EYE.units = [];
EYE.units.pupil = pupil_units;
EYE.units.gaze = [];
EYE.units.gaze.x = gaze_units_x;
EYE.units.gaze.y = gaze_units_y;

%% Get events

EYE.event = struct(...
    'name', event_types,...
    'time', num2cell(event_times/1000));

end