
function EYE = pupl_reloadraw(EYE)

fprintf('Reloading raw data...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    EYE(dataidx) = EYE(dataidx).getraw();
    fprintf('done\n');
end
fprintf('Done\n');

end