
function out = unfold(varargin)

% unfold(x, y) == unfold([x y]) == x:y

if numel(varargin) == 1
    x = varargin{1}(1);
    y = varargin{1}(2);
elseif numel(varargin) == 2
    [x, y] = varargin{:};
end

out = linspace(x, y, y - x + 1);

end