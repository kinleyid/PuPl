
function out = all2str(varargin)

if nargin > 1
    out = '';
    out = cellfun(@(x) sprintf('%s, ', all2str(x)), varargin, 'UniformOutput', false);
    out = [out{:}];
    out(end-1:end) = []; % Get rid of last comma and space
else
    in = varargin{1};
    if isnumeric(in) || islogical(in)
        out = mat2str(in);
    elseif ischar(in)
        out = sprintf('''%s''', in);
    elseif iscell(in)
        if isempty(in)
            out = '{}';
        else
            out = cellfun(@all2str, in, 'UniformOutput', false)';
            fmt = repmat('%s ', 1, size(out, 1));
            fmt(end) = ';';
            out = ['{' sprintf(fmt, out{:})];
            out(end) = '}';
        end
    elseif isstruct(in)
        out = 'struct(';
        for field = reshape(fieldnames(in), 1, [])
            out = sprintf('%s''%s'', %s, ', out, field{:}, all2str({in.(field{:})}));
        end
        out = [out(1:end-2) ')']; % Remove last comma and space
    elseif isempty(in)
        out = '[]';
    elseif strcontains(class(in), 'function')
        out = func2str(in);
        if out(1) ~= '@'
            out = ['@' out];
        end
    end
end

end