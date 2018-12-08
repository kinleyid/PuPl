function EYE = PFEdetrend(EYE, varargin)

fprintf('Detrending...\n')
for dataIdx = 1:numel(EYE)
    fprintf('\t%s\n', EYE(dataIdx).name)
    for stream = {'left' 'right'}
        currData = EYE(dataIdx).data.(stream{:})(:);
        currCoord = EYE(dataIdx).gaze.y(:);
        badIdx = isnan(currData) | isnan(currCoord);
        currData = currData(~badIdx);
        currCoord = currCoord(~badIdx);
        detrendParams = [currCoord ones(size(currCoord))] \ currData;
        fprintf('\t%s = %0.2f + %0.2f*gaze_y\n', stream{:}, detrendParams(2), detrendParams(1))
        est = EYE(dataIdx).gaze.y*detrendParams(1);
        est = est - mean(est, 'omitnan');
        EYE(dataIdx).data.(stream{:}) = EYE(dataIdx).data.(stream{:}) - est;
    end
end

end