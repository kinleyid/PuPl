
function eventlog = loadpresentationlog(fullpath)

% Input: full path to file

tab = sprintf('\t');

raw = fastfileread(fullpath);
lines = regexp(raw, sprintf('\n'), 'split');
halfstarts = find(strcontains(lines, 'Event Type'));
secondhalfstart = halfstarts(2);
colnames = regexp(lines{secondhalfstart}, tab, 'split');
contents = strrep([lines{secondhalfstart+2:end}], sprintf('\r'), tab);
contents = reshape(regexp(contents(1:end-1), tab, 'split'), numel(colnames), [])';

eventtypes = cellfun(@(x) [x{:}], num2cell(contents(:, 1:4), 2), 'UniformOutput', false);
RTs = str2double(contents(:, strcmp(colnames, 'RT'))) / 10 / 1000; % Presentation records time in 10ths of milliseconds
eventtimes = str2double(contents(:, strcmp(colnames, 'Time'))) / 10 / 1000;

eventlog = struct(...
    'event', struct(...
        'type', eventtypes(:)',...
        'time', num2cell(eventtimes(:)'),...
        'rt', num2cell(RTs(:)')));

end