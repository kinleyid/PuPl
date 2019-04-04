
function out = isnonemptyfield(structArray, varargin)

out = true;

if isempty(varargin)
    if isempty(structArray)
        out = false;
    end
    return
end

try 
    if isempty(mergefields(structArray, varargin{:}))
        out = false;
    end
catch
    out = false;
end

end