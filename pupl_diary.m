function pupl_diary(varargin)

p = inputParser;
addParameter(p, 'filename', []);
addParameter(p, 'directory', [])
parse(p, varargin{:});

priordir = pwd;
if isempty(p.Results.filename)
    if ~isempty(p.Results.directory)
        cd(p.Results.directory)
    end
    [filename, directory] = uiputfile('*.txt', '', ['eye-data-proc-' date]);
    if isnumeric(filename)
        warning('Processing history will not be logged');
        return
    end
else
    filename = p.Results.filename;
    if isempty(p.Results.directory)
        directory = priordir;
    end
end

fprintf('Logging processing to %s%s\n', directory, filename);

diary([directory filename]);
diary on

cd(priordir)
    
end