
function outtime = parsetimestr(timestr, srate)

%   Inputs
% timestr--something with ms, m, s, dp, or d
% srate--sample rate
%   Outputs
% outtime--time in seconds

cmd = lower(timestr);
cmd = strrep(cmd,' ','');

for x = {'ms' 'm'}
    cmd = strsubconstval(cmd, x{:}, '(1/1000)');
end
for x = {'s'}
    cmd = strsubconstval(cmd, x{:}, '1');
end
for x = {'dp' 'd'}
    cmd = strsubconstval(cmd, x{:}, sprintf('%f', 1/srate));
end

outtime = eval(cmd);

end