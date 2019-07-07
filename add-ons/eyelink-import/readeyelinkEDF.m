
function EYE = readeyelinkEDF(fullpath)

fid = fopen(fullpath, 'rb');
chardata = fread(fid, 268, 'uint8=>char')';
fclose(fid);

msg = '! ¡Ð^';

fid = fopen(fullpath, 'rb');
numdata = fread(fid, 'single');
fclose(fid);

msgidx = strfind(chardata, 'Instruction');
for ii = 1:100
    disp(chardata(msgidx(ii)-20:msgidx(ii)+20));
end

'  0! L¿^ ('
'  0! ?x^ '''
[~, preambleend] = regexp(chardata, sprintf('ENDP:\n'));
lines = regexp(chardata, '.*', 'match', 'dotexceptnewline');
tokens = regexp(chardata, '^.', 'match', 'lineanchors');

'! '

end