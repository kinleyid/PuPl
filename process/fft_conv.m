
function data = fft_conv(data, win, varargin)

% FFT-based convolution
%
% Inputs:
%   data: array
%       data to be filtered
%   win: array
%       kernel to be convolved with the data
%   varargin:
%       {1}: 'omitnan'
%           Omit NaN values

if isempty(varargin)
    omitnan = false;
elseif strcmp(varargin{1}, 'omitnan')
    omitnan = true;
end

nwin = numel(win);
nconv = nwin + numel(data) - 1;
wasnan = isnan(data);
data(wasnan) = 0;
% win = win/sum(win); % Normalize here instead of dividing the FT
winx = fft(win(:)', nconv);
% winx = winx / max(winx);
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

data = real(data); % In Octave, the imaginary parts are still returned even if they're all 0

end
