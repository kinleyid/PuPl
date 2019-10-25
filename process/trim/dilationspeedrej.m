
function EYE = dilationspeedrej(EYE, varargin)

p = inputParser;
addParameter(p, 'thresh', []);
parse(p, varargin{:});

if isempty(p.Results.thresh)
    % Compute d prime for all datasets
    alld = {};
    for dataidx = 1:numel(EYE)
        for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
            alld{end + 1} = dprime(EYE(dataidx).diam.(stream{:}));
        end
    end
    alld = cell2mat(alld);
    thresh = UI_cdfgetrej(alld, 'threshname', 'Dilation speed');
    if isempty(thresh)
        return
    end
else
    thresh = p.Results.thresh;
end

fprintf('Removing datapoints with dilation speed above %s...\n', thresh);

for dataidx = 1:numel(EYE)
    fprintf('\t%s...\n', EYE(dataidx).name);
    for field = reshape(fieldnames(EYE(dataidx).diam), 1, [])
        fprintf('\t\t%s: ', field{:});
        dp = dprime(EYE(dataidx).diam.(field{:}));
        currthresh = parsedatastr(thresh, dp);
        isrej = dp >= currthresh;
        pctrej = 100*nnz(isrej)/numel(dp);
        fprintf('%f%% rejected\n', pctrej);
        EYE(dataidx).diam.(field{:})(isrej) = NaN;
    end
    EYE(dataidx).history{end + 1} = getcallstr(p);
end
fprintf('Done\n');

end

function dp = dprime(x)

ad = abs(diff(x));
dp = [ad(1) max([ad(1:end-1); ad(2:end)]) ad(end)];

end