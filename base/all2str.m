
function out = all2str(in)

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