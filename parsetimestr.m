
function outtime = parsetimestr(timestr, srate)

cmd = lower(timestr);
cmd = strrep(cmd,' ','');

for x = {'milliseconds' 'ms' 'm'}
    cmd = replacewith(cmd, x{:}, '1/1000');
end
for x = {'seconds' 's'}
    cmd = replacewith(cmd, x{:}, '1');
end
for x = {'datapoints' 'dp' 'd'}
    cmd = replacewith(cmd, x{:}, sprintf('%f', 1/srate));
end

outtime = eval(cmd);

end

function cmd = replacewith(cmd, fnd, repl)

[a, b] = regexp(cmd, ['[0-9]' fnd]);
if ~isempty(b)
    for i = 1:numel(b)
        cmd = strcat(cmd(1:a(i)), ['*' fnd], cmd(b(i)+1:end));
    end
end
cmd = strrep(cmd,fnd,repl);

end