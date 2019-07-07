
fullpath = 'C:\Users\isaac\Projects\eyedata\eyedata.edf';
fid = fopen(fullpath, 'rb');
chardata = fread(fid, 'uint8=>char')';
[~, preambleend] = regexp(chardata, sprintf('ENDP:\n'));
frewind(fid);
preamble = fread(fid, preambleend-10, 'uint8=>char')';
% The next few bits must identify a message
bindata = fread(fid, 'uint8=>char')';
% We know there are 7 "MSG"s in this file
chardata = char(bindata);
finds = {};
for ii1 = 1:100
    for ii2 = 1:100
        nmsgs = numel(strfind(chardata, chardata(ii1:ii2)));
        if nmsgs == 7
            finds{end+1} = [ii1 ii2];
        elseif nmsgs < 7
            break
        end
    end
end