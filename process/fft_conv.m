
function data = fft_conv(data, win, varargin)

if isempty(varargin)
    omitnan = false;
elseif strcmp(varargin{1}, 'omitnan')
    omitnan = true;
end

% FFT-based convolution, ignoring NaNs
nwin = numel(win);
nconv = nwin + numel(data) - 1;
wasnan = isnan(data);
data(wasnan) = 0;
winx = fft(win(:)', nconv);
winx = winx / max(winx);
datax = fft(data(:)', nconv);
mult = winx.*datax;
data = ifft(mult);
hw = floor(nwin/2) + 1;
if hw > 1
    data = data(hw-1:end-hw);
end
if omitnan
    % Correct for NaNs
    o = ones(size(data));
    o(wasnan) = 0;
    ox = fft(o(:)', nconv);
    mult = winx.*ox;
    sums = ifft(mult);
    if hw > 1
        sums = sums(hw-1:end-hw);
    end
    % Renormalize
    data = data ./ sums;
    data(wasnan) = nan;
end

end