function EYE = rejecttrialsbymissingppn(EYE, varargin)

%   Inputs
% EYE--struct array
%   Outputs
% EYE--struct array

p = inputParser;
addParameter(p, 'lims', []);
addParameter(p, 'threshold', []);
parse(p, varargin{:});

if isempty(p.Results.lims)
    lims = (inputdlg(...
        {sprintf('Window start:')
        'Window end:'}));
    if isempty(lims)
        return
    end
else
    lims = p.Results.lims;
end

if isempty(p.Results.threshold)
    missingPpns = getmissingppns(EYE, lims);
    threshold = UI_cdfgetrej([missingPpns{:}], 'dataname', 'trials', 'lims', [0 1], 'threshname', 'Proportion of data missing');
    if isempty(threshold)
        return
    end
else
    threshold = p.Results.threshold;
end

fprintf('Rejecting trials with >= %0.1f%% missing data...\n', threshold*100);

missingPpns = getmissingppns(EYE, lims);

for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    isrej = missingPpns{dataidx} >= threshold;
    wasrej = [EYE(dataidx).epoch.reject];
    newrej = isrej & ~wasrej;
    fprintf('%d above threshold, %d newly rejected, %d/%d total rejected\n',...
        nnz(isrej), nnz(newrej), nnz(wasrej) + nnz(newrej), numel(EYE(dataidx).epoch));
    [EYE(dataidx).epoch(newrej).reject] = deal(true);
    EYE(dataidx).history{end + 1} = getcallstr(p);
end

fprintf('Done\n')

end