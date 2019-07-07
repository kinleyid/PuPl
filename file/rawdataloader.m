
function out = rawdataloader(loadfunc, fullpath, varargin)

% Adds fills out raw data

out = loadfunc(fullpath, varargin{:});
out.src = fullpath;
[~, n] = fileparts(fullpath);
out.name = n;
for field = {'gaze' 'diam'}
    out.(field{:}) = getfromur(out, field{:});
end
out = pupl_check(out);

end