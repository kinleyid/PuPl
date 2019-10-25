function EYE = trimshort(EYE, varargin)

p = inputParser;
addParameter(p, 'lenthresh', []); % Max allowable length
addParameter(p, 'septhresh', []);
parse(p, varargin{:});

if isempty(p.Results.lenthresh)
    prompt = 'Trim islands of data shorter than or equal to ____:';
    lenthresh = inputdlg(prompt, prompt, [1 50], {'100ms'});
    if isempty(lenthresh)
        EYE = [];
        return
    end
    lenthresh = lenthresh{:};
else
    lenthresh = p.Results.lenthresh;
end

if isempty(p.Results.septhresh)
    prompt = 'Trim islands of data at least ____ from the nearest other datapoint:';
    septhresh = inputdlg(prompt, prompt, [1 50], {'100ms'});
    if isempty(septhresh)
        EYE = [];
        return
    end
    septhresh = septhresh{:};
else
    septhresh = p.Results.septhresh;
end

fprintf('Trimming islands of data shorter than or equal to %s isolated by at least %s\n', lenthresh, septhresh);

for dataidx = 1:numel(EYE)
    currlenthresh = timestr2lat(EYE(dataidx), lenthresh);
    currsepthresh = timestr2lat(EYE(dataidx), septhresh);
    fprintf('\t%s: trimming islands of data shorter than or equal to %d samples isolated by at least %d samples\n', EYE(dataidx).name, currlenthresh, currsepthresh);
    for field = reshape(fieldnames(EYE(dataidx).diam), 1, [])
        lenviolators = identifyconsecutive(EYE(dataidx).diam.(field{:}), currlenthresh, @(x) ~isnan(x));
        sepviolators = identifyconsecutive(EYE(dataidx).diam.(field{:}), currsepthresh, @isnan, 'least');
        bookends = (lenviolators & [sepviolators(2:end) false]) | ...
            (lenviolators & [false sepviolators(1:end-1)]);
        trimidx = findbookended(lenviolators, bookends) | ...
            findbookended(fliplr(lenviolators), fliplr(bookends));
        fprintf('\t\t%s: %0.2f%% removed\n', field{:}, 100*nnz(trimidx)/numel(trimidx));
        EYE(dataidx).diam.(field{:})(trimidx) = nan;
    end
    EYE(dataidx).history{end + 1} = getcallstr(p);
end
fprintf('Done\n')

end

function dout = findbookended(din, indic) % Can't think of a clever vectorized way to do this

dout = false(size(din));
wasindic = false;

for ii = 1:numel(din)
    if indic(ii)
        wasindic = true;
    end
    
    if din(ii)
        if wasindic
            dout(ii) = true;
        end
    else
        wasindic = false;
    end
end

end