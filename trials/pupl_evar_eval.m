
function out = pupl_evar_eval(expr, varargin)

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
% Ensure all inputs are of the same size
evs = varargin;
numels = cellfun(@numel, evs);
[M, I] = max(numels);
small_idx = numels ~= M;
if any(small_idx)
    max_size = size(evs{I});
    evs(small_idx) = cellfun(@(x) repmat(x, max_size), evs(small_idx), 'UniformOutput', false);
end

out = arrayfun(func, evs{:}, 'UniformOutput', false);

end