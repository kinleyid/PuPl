
function eventlog = pupl_mat(fullpath, varargin)

% Load event logs in .mat format
m = load(fullpath);
fn = fieldnames(m);
eventlog = m.(fn{1});
if ~isstruct(eventlog)
    error('Expected a struct but found a %s', class(eventlog));
end
colnames = fieldnames(eventlog);
for reqname = {'time' 'name'}
    if ~ismember(reqname{:}, colnames)
        error('Event logs require %s as a fieldname', reqname{:})
    end
end

end
