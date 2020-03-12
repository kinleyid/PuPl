
function out = cellstr2num(in)

% Returns column vec

if any(cellfun(@ischar, in)) % nan can be read like char
    out = sscanf(sprintf('%s ', in{:}), '%g');
else
    out = [in{:}]'; % assume all numeric
end

end