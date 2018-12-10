function EYE = deleteblinks(EYE)

fprintf('Deleting blink data points')

for dataidx = 1:numel(EYE)
    fprintf('\t%s:\n', EYE(dataidx).name)
    for field = reshape(fieldnames(EYE(dataidx).diam), 1, [])
        fprintf('\t\t%s: %0.2f%% deleted\n', field{:}, 100*nnz(~isnan(EYE(dataidx).diam.(field{:})) & EYE(dataidx).isBlink)/numel(EYE(dataidx).isBlink))
        EYE(dataidx).diam.(field{:})(EYE(dataidx).isBlink) = nan;
    end
end

end