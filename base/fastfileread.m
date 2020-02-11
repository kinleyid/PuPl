
function data = fastfileread(fullpath)
% Thank you stackexchange
fid = fopen(fullpath, 'r');
data = fread(fid, getfield(dir(fullpath), 'bytes'), 'uint8=>char')';
dataIncrement = fread(fid, 1, 'uint8=>char');
while ~isempty(dataIncrement) && (dataIncrement(end) ~= eol) && ~feof(fid)
    dataIncrement(end+1) = fread(fid,1,'uint8=>char');  %This can be slightly optimized
end
fclose(fid);
data = [data dataIncrement];

end