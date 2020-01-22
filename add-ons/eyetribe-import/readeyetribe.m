function EYE = readeyetribe(fullpath)

json = fastfileread(fullpath);
json = regexprep(json, '\r', '');
samples = cellfun(@parse_json, regexp(json, '\n', 'split'));

x = 10;

end