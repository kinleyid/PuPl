
function EYE = pupl_reload(EYE)

for dataidx = 1:numel(EYE)
    elog = EYE(dataidx).eventlog;
    tmp = feval(str2func(EYE(dataidx).getraw));
    [EYE, tmp] = fieldconsistency(EYE, tmp);
    EYE(dataidx) = tmp;
    EYE(dataidx).eventlog = elog;
end

end