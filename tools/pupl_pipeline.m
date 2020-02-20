
function EYE = pupl_pipeline(EYE, varargin)

global pupl_globals

p = inputParser;
addParameter(p, 'scriptpath', []);
parse(p, varargin{:});

if isempty(p.Results.scriptpath)
    [f, p] = uigetfile('*.m', 'Select pipeline script');
    if f == 0
        return
    else
        scriptpath  = sprintf('%s', p, f);
    end
else
    scriptpath = p.Results.scriptpath;
end

fprintf('Running pipeline %s\n', scriptpath);
eval(sprintf('%s = EYE;', pupl_globals.datavarname));
run(scriptpath);
eval(sprintf('EYE = %s;', pupl_globals.datavarname));
fprintf('\nDone\n');
end