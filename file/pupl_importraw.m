
function out = pupl_importraw(loadfunc)

out = struct([]);
[filenames, directory] = uigetfile('*.*',...
    'MultiSelect', 'on');
if isnumeric(filenames)
    return
end
filenames = cellstr(filenames);

fprintf('Importing raw data...\n')
for dataidx = 1:numel(filenames)
    fprintf('\t%s...\n', filenames{dataidx});
    currsrc = fullfile(directory, filenames{dataidx});
    currdata = loadfunc(currsrc);
    currdata.name = filenames{dataidx};
    currdata.src = currsrc;
    currdata.getraw = str2func(sprintf('@()%s(''%s'')', func2str(loadfunc), currsrc));
    out = cat(2, out, currdata);
end
fprintf('Done\n');

end