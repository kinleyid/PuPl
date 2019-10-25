
function EYE = rejecttrialsbyextremediam(EYE, varargin)

p = inputParser;
addParameter(p, 'thresh', []);
parse(p, varargin{:});

data = cellfun(@(x) max(abs(x)), getalltrialdata(EYE, 'diam', 'both'));
if isempty(p.Results.thresh)
    thresh = UI_cdfgetrej(data, 'dataname', 'trials', 'threshname', 'Max abs. value in trial');
    if isempty(thresh)
        return
    end
else
    thresh = p.Results.thresh;
end
numthresh = parsedatastr(thresh, data); % Convert from string to number

fprintf('Rejecting trials by extreme pupil size measurements...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    isrej = getextremediam(EYE(dataidx)) >= numthresh;
    wasrej = [EYE(dataidx).epoch.reject];
    newrej = isrej & ~wasrej;
    fprintf('%d above threshold, %d newly rejected, %d total rejected\n', nnz(isrej), nnz(newrej), nnz(wasrej) + nnz(newrej));
    [EYE(dataidx).epoch(newrej).reject] = deal(true);
    EYE(dataidx).history{end + 1} = getcallstr(p);
end
fprintf('Done\n');

end

function out = getextremediam(EYE)

out = cellfun(@(x) max(abs(x)), gettrialdata(EYE, [], 'diam', 'both'));

end