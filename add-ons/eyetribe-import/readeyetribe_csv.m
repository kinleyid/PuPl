
function out = readeyetribe_csv(fullpath)

raw = readdelim2cell(fullpath, ',');
cols = raw(1, :);
contents = raw(2:end, :);

timestamps = contents(:, strcmp(cols, 'timestamp'));
timestamps = regexp(timestamps, '....-..-.. (\d+):(\d+):(\d+)\.(\d+)', 'tokens');
timestamps = cat(1, timestamps{:});
timestamps = cat(1, timestamps{:});
h = cellstr2num(timestamps(:, 1)) * 60*60;
m = cellstr2num(timestamps(:, 2)) * 60;
s = cellstr2num(timestamps(:, 3));
ms = cellstr2num(timestamps(:, 4)) / 1000;

event = struct(...
    'time', num2cell(h + m + s + ms),...
    'name', contents(:, strcmp(cols, 'message')));
out = struct(...
    'event', event);

end
