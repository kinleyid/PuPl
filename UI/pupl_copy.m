
function EYE = pupl_copy(EYE)

for dataidx = 1:numel(EYE)
    EYE(dataidx).name = ['Copy of ' EYE(dataidx).name];
end

end