
function res = parsedatastr(cmd, data)

%   Inputs
% cmd--string: command to be evaluated
% data--numerical array: data from which statistics will be computed

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

shorthands = {
    '`mu' @nanmean_bc
    '`md' @nanmedian_bc
    '`mn' @min
    '`mx' @max
    '`sd' @nanstd_bc
    '`vr' @nanvar_bc
    '`iq' @interquartilerange
    '`madv' @medianabsdev
};

for ii = 1:size(shorthands, 1)
    if numel(regexp(cmd, shorthands{ii, 1})) > 0
        cmd = strsubconstval(cmd, shorthands{ii, 1}, all2str(shorthands{ii, 2}(data)));
    end
end

if numel(regexp(cmd, '\$')) > 0
    cmd = strsubconstval(cmd, '\$', 'data');
end

try
    res = eval(cmd);
catch
    res = nan;
end

if ischar(res)
    res = str2double(res);
    if isempty(res)
        res = nan;
    end
end

end