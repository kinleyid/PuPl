
function EYE = pupl_reload(EYE)

for dataidx = 1:numel(EYE)
    elog = EYE(dataidx).eventlog;
    EYE(dataidx) = feval(str2func(EYE(dataidx).getraw));
    EYE(dataidx).eventlog = elog;
end

end