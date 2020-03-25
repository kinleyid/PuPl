
function printprog(varargin)

persistent m; % Max
if strcmp(varargin{1}, 'setmax')
    m = varargin{2};
    str = ['[' repmat(' ', 1, m) ']'];
    fprintf(str);
else
    fprintf(repmat('\b', 1, m + 2));
    n = varargin{1};
    str = ['[' repmat('-', 1, n) repmat(' ', 1, m - n) ']'];
    fprintf(str);
    if n == m
        fprintf('\n');
    end
end

end