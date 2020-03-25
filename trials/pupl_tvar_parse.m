
function var = pupl_tvar_parse(ev, expr, varargin)

if numel(varargin) == 0
    n = 1; % How many variables will be returned?
else
    n = varargin{1};
end

var = cell(1, n);
[var{:}] = eval(regexprep(expr, '#', 'ev.'));
if n == 1
    var = var{1};
end

end