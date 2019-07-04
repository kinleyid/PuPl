
function data = sub_load(fullpath)

data = dataloader(@loadeyedata, fullpath);
data = pupl_check(data);

end