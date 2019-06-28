function EYE = rejecttrialsbymissingppn(EYE, varargin)

%   Inputs
% EYE--struct array
%   Outputs
% EYE--struct array

p = inputParser;
addParameter(p, 'lims', []);
addParameter(p, 'threshold', []);
parse(p, varargin{:});
callStr = sprintf('eyeData = %s(eyeData, ', mfilename);

if isempty(p.Results.lims)
    lims = (inputdlg(...
        {sprintf('Examine periods beginning at this time relative to events that define trials:')
        'Examine periods ending at this time relative to events that define trials:'}));
    if isempty(lims)
        return
    end
else
    lims = p.Results.lims;
end
callStr = sprintf('%s''lims'', %s, ', callStr, all2str(lims));

if isempty(p.Results.threshold)
    missingPpns = getmissingppns(EYE, lims);
    threshold = UI_cdfgetrej(missingPpns, [0 1]);
    if isempty(threshold)
        return
    end
else
    threshold = p.Results.threshold;
end
callStr = sprintf('%s''threshold'', %s)', callStr, all2str(threshold));

fprintf('Rejecting trials with >= %0.1f%% missing data...\n', threshold*100);

missingPpns = getmissingppns(EYE, lims);

for dataIdx = 1:numel(EYE)
    nRej = 0;
    for epochIdx = 1:numel(EYE(dataIdx).epoch)
        if missingPpns{dataIdx}(epochIdx) >= threshold
            EYE(dataIdx).epoch(epochIdx).reject = true;
            nRej = nRej + 1;
        end
    end
    fprintf('\t%s:\n\t\t%d/%d trials rejected\n',...
        EYE(dataIdx).name,...
        nRej,...
        numel(EYE(dataIdx).epoch));
    fprintf('\t\t%d trials total marked for rejection\n', nnz([EYE(dataIdx).epoch.reject]));
    EYE(dataIdx).history = [
        EYE(dataIdx).history
        callStr
    ];
end

fprintf('Done\n')

end