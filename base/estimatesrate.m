
function srate = estimatesrate(timestamps)

% Assumes timestamps are in units of seconds

srate = round((numel(timestamps) - 1)/((max(timestamps) - min(timestamps))));

end