
function out = loader(rawindicator, type, loadfunc, fullpath, varargin)

% This deals with low-level structural stuff all in one place

out = loadfunc(fullpath, varargin{:});
[~, n] = fileparts(fullpath);
out.name = n;
if strcmp(rawindicator, 'raw')
    out.src = fullpath;
    if strcmp(type, 'eye')
        out = pupl_check(out);
        for field = {'gaze' 'diam'}
            out.(field{:}) = getfromur(out, field{:});
        end
    end
end

end