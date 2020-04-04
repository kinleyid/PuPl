
function var = pupl_evar_get(expr, varargin)

% varargin is events
% This could probably be vectorized

idx = regexp(expr, '#[^\d]\s*');
n = 0;
for i = idx
    adj_i = i + n;
    expr = [expr(1:adj_i-1) '#1' expr(adj_i+1:end)];
    n = n + 1; % The whole string has just gotten longer by 2 characters
end

for n = 1:numel(varargin)
    expr = regexprep(expr, ['#\s*' num2str(n) '\s*'], sprintf('varargin{%d}.', n));
end

var = eval(expr);

end