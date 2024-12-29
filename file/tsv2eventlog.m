
function eventlog = tsv2eventlog(fullpath)

[raw, src] = readdelim2cell(fullpath, '\t', '#');
if isempty(src)
    src = fullpath;
end

cols = raw(1, :);
contents = raw(2:end, :);

contents(strcmp(contents(:), 'n/a')) = {'nan'};

times = cellstr2num(contents(:, strcmp(cols, 'onset')));

events = struct(...
    'time', num2cell(times),...
    'name', contents(:, strcmp(cols, 'trial_type')));

rts = cellstr2num(contents(:, strcmp(cols, 'response_time')));
if ~isempty(rts)
    rts = num2cell(rts);
    [events.rt] = deal(rts{:});
end

for othername = cols(~ismember(cols, {'onset' 'duration' 'trial_type' 'response_time'}))
    curr_col = contents(:, strcmp(cols, othername{:}));
    as_numeric = cellfun(@str2double, curr_col);
    if any(~isnan(as_numeric))
        curr_col = num2cell(as_numeric);
    end
    [events.(othername{:})] = deal(curr_col{:});
end

[~, n] = fileparts(fullpath);

eventlog = struct(...
    'name', n,...
    'src', src,...
    'event', events(:)');

end
