
function srate = estimatesrate(timestamps)

srate = round((numel(timestamps) - 1)/((max(timestamps) - min(timestamps))), -1); % Assume no srates that aren't multiples of to

end