
function out = cellstr2num(in)

% Returns column vec

if ischar(in{1})
    out = sscanf(sprintf('%s ', in{:}), '%g');
else
    out = [in{:}]';
end

end