
function writeAOIstats(EYE, varargin)

p = inputParser;
addParameter(p, 'path', []);
parse(p, varargin{:});

if isempty(p.Results.path)
    [file, dir] = uiputfile('*');
    path = sprintf('%s', dir, file);
else
    path = p.Results.path;
end

allStats = unique(mergefields(EYE, 'aoi', 'stat', 'name'));

for dataidx = 1

writetable(statsTable, path);

end