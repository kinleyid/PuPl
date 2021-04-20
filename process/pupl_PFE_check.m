
function pupl_PFE_check(pre, post)
% Check if pupil foreshortening error has introduced


end


function out = pk2pk(x, win_len)

% moving window peak-to-peak distance
%
% x:        data
% n:        half filter width
% filtfunc: filtering function (mean or median)

p2p = @(x) max(x) - min(x);

x_size = size(x);

x = x(:); % Original data
pd = [nan; x; nan(win_len-1, 1)]; % Padded
nd = numel(x); % Amount of data
rb = pd(1:win_len); % Window of data, a ring buffer

% replidx(i) is the index of the ring buffer to overwrite at step i
replidx = repmat((1:win_len)', ceil(nd/(win_len)), 1);
replidx = replidx(1:nd);

for latidx = 1:nd
    rb(replidx(latidx)) = pd(latidx + win_len);
    x(latidx) = p2p(rb);
end

out = reshape(x, x_size);

end