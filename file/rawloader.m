
function out = rawloader(loadfunc, fullpath)

out = loadfunc(fullpath);
out.src = fullpath;
[~, n] = fileparts(fullpath);
out.name = n;

end