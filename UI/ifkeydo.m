
function ifkeydo(e, keys, func)

if ~iscell(func)
    func = {func};
end

keys = cellstr(keys);

if ismember(e.Key, keys)
    for idx = 1:numel(func)
        feval(func{idx});
    end
end

end