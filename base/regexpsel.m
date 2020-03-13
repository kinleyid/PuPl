
function [idx, selected] = regexpsel(str, expr)

if any(cellfun(@isnumeric, expr))
    re = regexp(str, expr{2});
    if ~iscell(re)
        re = {re};
    end
    idx = ~cellfun(@isempty, re);
    selected = str(idx);
else
    idx = ismember(str, expr);
    selected = reshape(str, 1, []);
end

end