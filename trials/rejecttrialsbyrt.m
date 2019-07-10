
function EYE = rejecttrialsbyrt(EYE, varargin)

p = inputParser;
addParameter(p, 'lims', []);
parse(p, varargin{:});

if isempty(p.Results.lims)
    rts = mergefields(EYE, 'epoch', 'event', 'rt');
    lims = UI_histgetrej(rts, 'dataname', 'Reaction time');
    if isempty(lims)
        return
    end
else
    lims = p.Results.lims;
end

fprintf('Rejecting trials with RT <= %s or RT >= %s...\n', lims{1}, lims{2});
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    rts = mergefields(EYE(dataidx), 'epoch', 'event', 'rt');
    for ii = 1:2
        currlims(ii) = parsedatastr(lims{ii}, rts);
    end
    isrej = rts <= currlims(1) | rts >= currlims(2);
    wasrej = [EYE(dataidx).epoch.reject];
    newrej = isrej & ~wasrej;
    fprintf('%d above threshold, %d newly rejected, %d total rejected\n', nnz(isrej), nnz(newrej), nnz(wasrej) + nnz(newrej));
    [EYE(dataidx).epoch(newrej).reject] = deal(true);
    EYE(dataidx).history{end + 1} = getcallstr(p);
end
fprintf('Done\n');

end