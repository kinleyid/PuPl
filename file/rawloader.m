
function out = rawloader(rawindicator, type, loadfunc, fullpath, varargin)

out = loadfunc(fullpath, varargin{:});
[~, n] = fileparts(fullpath);
out.name = n;
if strcmp(rawindicator, 'raw')
    out.src = fullpath;
end

if strcmp(type, 'eye') % Adds fields specific to eye data
    for field = {'gaze' 'diam'}
        out.(field{:}) = getfromur(out, field{:});
    end
    out = pupl_check(out);
end

end