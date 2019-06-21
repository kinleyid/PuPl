
function pupl_pipeline(EYE, varargin)

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
for dataidx = 1:numel(EYE)
    fprintf('\t\t%s\n', EYE(dataidx).name);
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
    eyeData = EYE(dataidx); % Processing scripts alter the variable "eyeData"
    run(scriptpath);
    EYE(dataidx) = eyeData; % Collect result from pipeline
end
fprinf('Done\n');
end