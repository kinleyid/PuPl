
function out = strsplit(tline, splitter)

[s, e] = regexp(tline, splitter);
e = [0 e];
s = [s numel(tline) + 1];
out = cell(1, numel(s));
for ii = 1:numel(s)
    out{ii} = tline(e(ii) + 1:s(ii) - 1);
end

end