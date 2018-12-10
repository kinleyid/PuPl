function EYE = mergedata(EYE, keyword)

for dataidx = 1:numel(EYE)
    switch keyword
        case 'diamxy'
            for field = reshape(fieldnames(EYE(dataidx).diam), 1, [])
                EYE(dataidx).diam.(field{:}) = mean([
                    EYE(dataidx).diam.(field{:}).x(:)'
                    EYE(dataidx).diam.(field{:}).y(:)']);
            end
        case 'gazelr'
            for field = reshape(fieldnames(EYE(dataidx).gaze), 1, [])
                EYE(dataidx).gaze.(field{:}) = mean([
                    EYE(dataidx).gaze.(field{:}).left(:)'
                    EYE(dataidx).gaze.(field{:}).right(:)']);
            end
    end
end

end