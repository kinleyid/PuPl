
function EYE = readeyelinkEDF(fullpath)

fid = fopen(fullpath, 'rb');
% Read header
header = '';
stopsig = 'EN';
b = repmat(' ', 1, numel(stopsig)); % Buffer
while ~strcmp(b, stopsig)
    c = fread(fid, 1, '*char'); % Current char
    b = [b(2:end) c];
    header(end + 1) = c;
end 

soughttime = uint32(786167);
pos = ftell(fid);
for nread = 0:2000
    for ii = 1:nread
        fread(fid, 1, 'bit1');
    end
    t = uint32(fread(fid, 1, 'uint32'));
    fprintf('%d\n', t);
    fseek(fid, pos, 'bof');
    if t == soughttime
        break
    end
end

% Brute force identification of message codes
time = fread(fid, 1, '*uint16')
mev = fread(fid, 1, 'int16');
len = fread(fid, 1, 'uint16');

msg = fread(fid, len, 'int8=>char');
fclose(fid);

end