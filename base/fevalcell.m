
function fevalcell(func)

if ~iscell(func)
    func = {func};
end

for idx = 1:numel(func)
    feval(func{idx});
end

end