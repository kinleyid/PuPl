
function cmd = strsubconstval(cmd, fnd, repl)

while true
    [a, b] = regexp(cmd, ['[0-9]' fnd]);
    if isempty(b)
        break
    else
        cmd = strcat(cmd(1:a(1)), ['*' fnd], cmd(b(1)+1:end));
    end
end

cmd = regexprep(cmd, fnd, repl);

end