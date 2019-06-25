
function lim = parsedatastr(str, data)

%   Inputs
% str--something with %, m, sd

cmd = lower(str);
cmd = strrep(cmd,' ','');

% Deal with percentiles
for x = {'%'}
    while true
        [s, e] = regexp(cmd, ['\d+(\.\d+)?' x{:}]);
        if isempty(s)
            break
        else
            cmd = [
                cmd(1:s(1)-1)...
                sprintf('%f', percentile(data, sscanf(cmd(s(1):e(1)), '%f')))...
                cmd(e(1)+1:end)
            ];
        end
    end
end
for x = {'mn'}
    cmd = strsubconstval(cmd, x{:}, sprintf('%f', nanmean_bc(data)));
end
for x = {'md'}
    cmd = strsubconstval(cmd, x{:}, sprintf('%f', nanmedian_bc(data)));
end
for x = {'sd'}
    cmd = strsubconstval(cmd, x{:}, sprintf('%f', nanstd_bc(data)));
end
for x = {'v'}
    cmd = strsubconstval(cmd, x{:}, sprintf('%f', nanvar_bc(data)));
end
for x = {'iq'}
    cmd = strsubconstval(cmd, x{:}, sprintf('%f', interquartilerange(data)));
end

try
    lim = eval(cmd);
catch
    lim = nan;
end

end