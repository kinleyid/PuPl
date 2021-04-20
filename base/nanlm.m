
function [B, Rsq, df, Yhat_nan] = nanlm(Y, varargin)
% Multivariate linear regression, ignoring NaNs
% 
% Usage:
% [coeff, Rsq, df] = nanlm(y, x1, x2, ...)

% Get x and y as columns
Y = Y(:);
X = cellfun(@(x) x(:), varargin, 'UniformOutput', false);
urX = cat(2, ones(size(Y)), X{:});
% Identify and exclude any incomplete rows
bad_idx = isnan(Y) | (sum(isnan(urX), 2) > 0);
Y = Y(~bad_idx);
X = urX(~bad_idx, :);
B = (X' * X) \ (X' * Y);
SStot = sum((mean(Y) - Y).^2);
Yhat = X * B;
SSres = sum((Yhat - Y).^2);
Rsq = 1 - SSres / SStot; 
df = numel(Y) - size(X, 2);
Yhat_nan = urX * B;

end