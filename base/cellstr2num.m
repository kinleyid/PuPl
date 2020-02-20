
function out = cellstr2num(in)

% Returns column vec

if ischar(in{1}) || isnan(in{1}) % nan can be read like char
    out = sscanf(sprintf('%s ', in{:}), '%g');
else
    out = [in{:}]'; % assume all numeric
end

end