function enterdo(e, func)

if ~iscell(func)
    func = {func};
end

if strcmp(e.Key, 'return')
    for idx = 1:numel(func)
        feval(func{idx});
    end
end

end