function EYE = interpeyedata(EYE, varargin)

p = inputParser;
addParameter(p, 'maxn', []);
parse(p, varargin{:});

if isempty(p.Results.maxn)
    prompt = 'Max number of samples to interpolate';
    maxn = inputdlg(prompt, prompt, [1 50], {'3'});
    if isempty(maxn)
        EYE = [];
        return
    else
        maxn = str2double(maxn{1});
    end
else
    maxn = p.Results.maxn;
end

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

fprintf('Interpolating max. %d points at a time\n', maxn)
for dataIdx = 1:numel(EYE)
    fprintf('\t%s:\n', EYE(dataIdx).name)
    for field = reshape(fieldnames(EYE(dataIdx).diam), 1, [])
        fprintf('\t\t%s: ', field{:});
        EYE(dataIdx).diam.(field{:}) = applyinterpolation(EYE(dataIdx).diam.(field{:}), maxn);
    end
end

end

function v = applyinterpolation(v, n)

interpidx = false(size(v));
i = 0;
flag = false;
while true
    i = i + 1;
    if i > numel(v)
        break
    end
    if isnan(v(i))
        j = 0;
        while true
            j = j + 1;
            if i + j > numel(v)
                flag = true;
                break
            end
            if ~isnan(v(i + j))
                if j <= n
                    interpidx(i:(i+j-1)) = true;
                end
                i = i + j;
                break
            end
        end
    end
    if flag
        break
    end
end

fprintf('%0.5f%% of data interpolated\n', 100*nnz(interpidx)/numel(interpidx))

v(interpidx) = interp1(find(~interpidx), v(~interpidx), find(interpidx) );

end