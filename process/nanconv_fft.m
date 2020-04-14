
function data = nanconv_fft(data, win)

% FFT-based convolution, ignoring NaNs
printprog('setmax', 8);
nwin = numel(win);
nconv = nwin + EYE.ndata - 1;
wasnan = isnan(data);
data(wasnan) = 0;
winx = fft(win(:)', nconv);
printprog(1);
winx = winx / max(winx);
datax = fft(data(:)', nconv);
printprog(2);
mult = winx.*datax;
printprog(3);
data = ifft(mult);
printprog(4);
hw = floor(nwin/2) + 1;
if hw > 1
    data = data(hw-1:end-hw);
end
% Correct for NaNs
o = ones(size(data));
o(wasnan) = 0;
ox = fft(o(:)', nconv);
printprog(5);
mult = winx.*ox;
printprog(6);
sums = ifft(mult);
printprog(7);
if hw > 1
    sums = sums(hw-1:end-hw);
end
% Renormalize
data = data ./ sums;
printprog(8);
data(wasnan) = nan;

end