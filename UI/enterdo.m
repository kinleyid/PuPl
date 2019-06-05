function enterdo(e, func)

if strcmp(e.Key, 'return')
    feval(func);
end

end