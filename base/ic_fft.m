
function idx = ic_fft(lg, n, varargin)

% Identify consecutive

if numel(varargin) == 1
    t = varargin{1};
else
    t = 'most';
end

if strcmp(t, 'most')
    n = n + 1;
end

% Logical to numeric
vec = double(lg(:));

starts = find([lg(1) == 1; diff(vec) == 1]);
ends = find([diff(vec) == -1; lg(end)]);

isnplus = find(fft_conv(vec(:), ones(n, 1)) > 0.999999); % Floating point weirdness

if any(isnplus)
    isnplus = isnplus([true diff(isnplus) > 1]);
end

switch t
    case 'least'
        idx = false(size(lg));
        for loc = isnplus
            winidx = loc >= starts & loc <= ends;
            if any(winidx)
                idx(starts(winidx):ends(winidx)) = true;
            end
        end
    case 'most'
        idx = logical(lg);
        for loc = isnplus
            winidx = loc >= starts & loc <= ends;
            if any(winidx)
                idx(starts(winidx):ends(winidx)) = false;
            end
        end
end

end

function v = fft_conv(v, k)

nkern = numel(k);
nconv = nkern + numel(v) - 1;
kernx = fft(k(:)', nconv);
kernx = kernx / max(kernx);
v = ifft(kernx .* fft(v(:)', nconv));
hw = floor(nkern/2) + 1;
if hw > 1
    v = v(hw-1:end-hw);
end

end