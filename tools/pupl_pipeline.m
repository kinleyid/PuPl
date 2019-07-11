
function EYE = pupl_pipeline(EYE, varargin)

p = inputParser;
addParameter(p, 'scriptpath', []);
parse(p, varargin{:});
callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

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

callstr = sprintf('%% %s''scriptpath'', %s)', callstr, all2str(scriptpath)); % Make it a comment

fprintf('Running pipeline %s\n', scriptpath);
eyeData = EYE;
run(scriptpath);
EYE = eyeData;
fprintf('\nDone\n');
end