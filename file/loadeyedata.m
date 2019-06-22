
function data = loadeyedata(fullpath)

data = getfield(load(fullpath, '-mat'), 'data');

end