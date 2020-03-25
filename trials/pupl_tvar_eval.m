
function out = pupl_tvar_eval(expr, varargin)

% each element of varargin is a vector of events

idx = regexp(expr, '#[^\d]\s*');
n = 0;
for i = idx
    adj_i = i + n;
    expr = [expr(1:adj_i-1) '#1' expr(adj_i+1:end)];
    n = n + 1; % The whole string has just gotten longer by 2 characters
end

for n = 1:numel(varargin)
    expr = regexprep(expr, ['#\s*' num2str(n) '\s*'], sprintf('e%d.', n));
end
func_head = '@(';
func_head = sprintf('%s%s', func_head, sprintf('e%d,', 1:numel(varargin)));
func_head(end) = ')';
func = sprintf('%s%s', func_head, expr);
func = str2func(func);

out = arrayfun(func, varargin{:}, 'UniformOutput', false);

end