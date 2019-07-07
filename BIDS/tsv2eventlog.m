
function eventlog = tsv2eventlog(fullpath)

[raw, src] = readdelim2cell(fullpath, '\t');
if isempty(src)
    src = fullpath;
end

names = raw(1, :);
events = struct(...
    'time', cellfun(@(s) sscanf(s, '%g'), raw(2:end, strcmp(names, 'onset')), 'un', 0),...
    'type', raw(2:end, strcmp(names, 'trial_type')),...
    'rt', cellfun(@(s) sscanf(s, '%g'), raw(2:end, strcmp(names, 'response_time')), 'un', 0));
for othername = names(~ismember(names, {'onset' 'trial_type' 'response_time'}))
    [events.(othername{:})] = raw{2:end, strcmp(names, othername{:})};
end

% Convert n/a and empty to nan
events = arrayfun(@(a) structfun(@processcells, a, 'UniformOutput', false), events);

[~, n] = fileparts(fullpath);

eventlog = struct(...
    'name', n,...
    'src', src,...
    'event', events);

end

function c = processcells(c)

if strcmp(c, 'n/a') || isempty(c)
    c = NaN;
end

end