
function out = isnonemptyfield(structArray, varargin)

out = true;

if isempty(structArray)
    out = false;
end

if isempty(varargin)
    if isempty(structArray)
        out = false;
    end
    return
end

try
    for idx = 1:numel(structArray)
        if isempty(mergefields(structArray(idx), varargin{:}))
            out = false;
        end
    end
catch
    out = false;
end

end