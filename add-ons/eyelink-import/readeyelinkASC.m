
% Based on
% http://sr-research.jp/support/EyeLink%201000%20User%20Manual%201.5.0.pdf,
% section 4.9

function EYE = readeyelinkASC(fullpath)

EYE = [];

%% Read raw

printprog('setmax', 14)
printprog(1)
rawdata = fastfileread(fullpath);
printprog(2)
% Get data lines
lines = regexp(rawdata, '.*', 'match', 'dotexceptnewline');
printprog(3)
% Get first characters of lines
tokens = regexp(rawdata, '^.', 'match', 'lineanchors');
printprog(4)
nonemptyidx = ~cellfun(@isempty, lines);
printprog(5)
tokens = tokens(nonemptyidx);
lines = lines(nonemptyidx);
printprog(6)

issample = ismember([tokens{:}], '123456789'); % Lines beginning with a number are data samples
printprog(7)
samples = lines(issample); % Data sample lines
infolines = lines(~issample); % All other lines contain metadata/events
printprog(8)
firstwords = cellfun(@(x) sscanf(x, '%s', 1), infolines, 'UniformOutput', false); % Other lines are identified by their first words
printprog(9)

%% Find data

samples = regexprep(samples, '\s\.\s', ' nan '); % Missing data are dots, replace with space-padded nan
printprog(10)
datamat = cell2mat(cellfun(@(x) sscanf(x, '%g'), samples, 'UniformOutput', false));
printprog(11)

% Find an info line beginning with "samples"
sampleinfo = lower(regexp(infolines{find(strcontains(lower(firstwords), 'samples'), 1)}, '\t', 'split'));
printprog(12)
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

printprog(13)
eventlines = infolines(strcontains(lower(firstwords), 'msg'));
event_times = nan(size(eventlines));
event_types = cell(size(eventlines));
for ii = 1:numel(eventlines)
    curreventinfo = regexp(eventlines{ii}, '\t', 'split');
    curreventinfo = regexp(curreventinfo{2}, '\s', 'split');
    event_times(ii) = sscanf(curreventinfo{1}, '%g');
    event_types{ii} = strtrim(sprintf('%s ', curreventinfo{2:end}));
end
printprog(14)
%% Process timestamps

EYE.srate = srate;
sample_times = datamat(1, :);
EYE.t1 = sample_times(1);
[sample_times, event_times] = processtimestamps(sample_times, event_times, srate);
EYE.times = sample_times;

%% Get events

EYE.event = struct(...
    'name', event_types,...
    'time', num2cell(event_times/1000));

end