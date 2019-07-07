
function eventlog = tsv2eventlog(fullpath)

[raw, src] = readdelim2cell(fullpath, '\t', '#');
if isempty(src)
    src = fullpath;
end

cols = raw(1, :);
contents = raw(2:end, :);

contents(strcontains(contents(:), 'n/a')) = {'nan'};

events = struct(...
    'time', cellfun(@(s) sscanf(s, '%g'), contents(:, strcmp(cols, 'onset')), 'un', 0),...
    'type', contents(:, strcmp(cols, 'trial_type')),...
    'rt', cellfun(@(s) sscanf(s, '%g'), contents(:, strcmp(cols, 'response_time')), 'un', 0));

for othername = cols(~ismember(cols, {'onset' 'trial_type' 'response_time'}))
    [events.(othername{:})] = raw{2:end, strcmp(cols, othername{:})};
end

[~, n] = fileparts(fullpath);

eventlog = struct(...
    'name', n,...
    'src', src,...
    'event', events(:)');

end