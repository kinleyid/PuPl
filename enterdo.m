function enterdo(e, func)

if strcmp(e.Key, 'return')
    func();
end

end