function x = percentile(data, p)

data = sort(data(~isnan(data)));
p = p / 100;
n = numel(data);
ps = (0:n-1) / n;
I1 = find(p > ps, 1, 'last');
I2 = find(p <= ps, 1);
t = find(p < ps, 1);
if isempty(I1)
    x = min(data);
elseif isempty(t)
    x = max(data);
else
    if data(I1) == data(I2)
        x = data(I1);
    else
        x = interp1([ps(I1) ps(I2)], [data(I1) data(I2)], p);
    end
end

end