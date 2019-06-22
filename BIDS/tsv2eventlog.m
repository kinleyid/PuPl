
function eventlog = tsv2eventlog(fullpath)

raw = readcell(fullpath, '\t');
names = raw(1, :);
eventlog = struct(...
    'time', cellfun(@str2double, raw(2:end, strcmp(names, 'onset')), 'un', 0),...
    'type', raw(2:end, strcmp(names, 'trial_type')),...
    'rt', cellfun(@str2double, raw(2:end, strcmp(names, 'response_time')), 'un', 0));
for othername = names(~ismember(names, {'onset' 'trial_type' 'response_time'}))
    [eventlog.(othername{:})] = raw{2:end, strcmp(names, othername{:})};
end

end