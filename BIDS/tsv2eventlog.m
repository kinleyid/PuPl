
function eventlog = tsv2eventlog(fullpath)

[raw, src] = readcell(fullpath, '\t');
if isempty(src)
    src = fullpath;
end

names = raw(1, :);
events = struct(...
    'time', cellfun(@str2double, raw(2:end, strcmp(names, 'onset')), 'un', 0),...
    'type', raw(2:end, strcmp(names, 'trial_type')),...
    'rt', cellfun(@str2double, raw(2:end, strcmp(names, 'response_time')), 'un', 0));
for othername = names(~ismember(names, {'onset' 'trial_type' 'response_time'}))
    [events.(othername{:})] = raw{2:end, strcmp(names, othername{:})};
end

events = structfun(@natonan, events);

[~, n] = fileparts(fullpath);

eventlog = struct(...
    'name', n,...
    'src', src,...
    'event', events);

end

function c = natonan(c)

for ii = 1:numel(c)
    if strcmp(c{ii}, 'n/a')
        c{ii} = NaN;
    end
end

end