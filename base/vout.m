function varargout = vout(in)

% Array to comma-separated list

if iscell(in)
    varargout = in;
else
    varargout = num2cell(in);
end

end