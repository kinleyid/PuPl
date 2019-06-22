
function out = readcell(fullpath, delim)

fid = fopen(fullpath);
out = [];
while true
    tline = fgetl(fid);
    if ~ischar(tline)
        break
    end
    out = cat(1, out, strsplit(tline, delim));
end
fclose(fid);

end