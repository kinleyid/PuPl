
function [out, header] = readcell(fullpath, delim)

fid = fopen(fullpath);
out = [];
header = {};
while true
    tline = fgetl(fid);
    if ~ischar(tline)
        break
    elseif strcmp(tline(1:2), '# ')
        header(end+1) = {tline(3:end)};
    else
        out = cat(1, out, strsplit(tline, delim));
    end
end
fclose(fid);

end