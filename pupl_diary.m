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
    [filename, directory] = uiputfile('*.txt', '', 'history');
    if isempty(filename)
        return
    end
else
    filename = p.Results.filename;
    if isempty(p.Results.directory)
        directory = priordir;
    end
end

diary([directory filename]);
diary

cd(priordir)
    
end