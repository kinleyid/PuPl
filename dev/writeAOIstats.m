
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
writetable(statsTable, path);

end