
function data = sub_load(fullpath)

[~, n] = fileparts(fullpath);
fprintf('Loading %s...', n);
data = loader([], 'eye', @loadeyedata, fullpath);
data = pupl_check(data);
fprintf('done');

end