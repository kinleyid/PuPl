
function outStructArray = pupl_loadtobiiexcel(varargin)

outStructArray = struct([]);

p = inputParser;
addParameter(p, 'filename', [])
addParameter(p, 'directory', '.')
addParameter(p, 'as', 'eye data')
parse(p, varargin{:});

directory = p.Results.directory;

if isempty(p.Results.filename)
    [filename, directory] = uigetfile([directory '\\*.*'],...
        'MultiSelect', 'on');
    if isnumeric(filename)
        return
    end
else
    filename = p.Results.filename;
end
filename = cellstr(filename);

for fileidx = 1:numel(filename)
    [~, name] = fileparts(filename{fileidx});
    fprintf('Importing %s\n', name)
    currStruct = loadtobiiexcel(sprintf('%s', directory, filename{fileidx}));
    fprintf('done\n')
    outStructArray = cat(1, outStructArray, currStruct);
end

outStructArray = pupl_check(outStructArray);

fprintf('done\n')

end