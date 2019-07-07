function out = mvavfilt(x, n, filtfunc)

xSize = size(x);

x = x(:);
p = [nan(n, 1); x; nan(n, 1)];
nd = numel(x);
n2 = n*2;
w = [nan; p(1:n2)];
replidx = repmat((1:2*n + 1)', ceil(nd/(2*n + 1)), 1);
replidx = replidx(1:nd);
for latidx = 1:nd
    w(replidx(latidx)) = p(latidx + n2);
    if ~isnan(x(latidx))
       x(latidx) = filtfunc(w);
    end
end

out = reshape(x, xSize);

end