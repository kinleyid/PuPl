
function y = gaussiankernel(v)

if numel(v) > 1
    x = (1:numel(v)) - (numel(v) + 1)/2;
    s = floor(numel(v)/2);
    Gau = exp(-((((x)/(s/3)).^2)));
    y = sum(Gau(:).*v(:),'omitnan');
    y = y/sum(Gau(~isnan(Gau)));
end

end