function EYE = rejecttrialsbyblinkproximity(EYE, varargin)

p = inputParser;
addParameter(p, 'lims', []);
parse(p, varargin{:});

if isempty(p.Results.lims)
    lims = cellfun(@str2double, inputdlg({
        'Reject epochs occurring fewer than this many ms after a blink:'
        'Reject epochs occurring fewer than this many ms before a blink:'},...
        'blinkLimsMs',...
        [1 100],...
        {'1000' '0'}));
    if isempty(lims)
        EYE = [];
        return
    end
else
    lims = p.Results.blinkLimsMs;
end

fprintf('Rejecting trials occuring fewer than %d ms after or %d ms before a blink...\n', lims(1), lims(2))

for dataIdx = 1:numel(EYE)
    nRejected = 0;
    latLims = ceil(lims/1000/EYE(dataIdx).srate);
    for epochIdx = 1:numel(EYE(dataIdx).epoch)
        currLats = EYE(dataIdx).epoch(epochIdx).latencies;
        currLims = [
            max(currLats(1) - latLims(1),...
                1);
            min(currLats(end) + latLims(2),...
                numel(EYE(dataIdx).isBlink))
            ];
        if any(EYE(dataIdx).isBlink(currLims(1):currLims(2)))
            EYE(dataIdx).epoch(epochIdx).reject = true;
            nRejected = nRejected + 1;
        end
    end
    fprintf('%s: %d/%d trials rejected\n',...
        EYE(dataIdx).name,...
        nRejected,...
        numel(EYE(dataIdx).epoch))
end

end