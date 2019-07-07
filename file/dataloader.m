
function out = dataloader(loadfunc, fullpath, varargin)

out = loadfunc(fullpath, varargin{:});
out.src = fullpath;
[~, n] = fileparts(fullpath);
out.name = n;

end