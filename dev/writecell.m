
function writecell(fullpath, data, delim)

% Write cell data to delimited text file

fmt = cell(1, size(data, 2)*2 - 1);
fmt(1:2:end) = '%s';
fmt(2:2:end-1) = {delim};
fmt = [fmt{:}];

fid = fopen(fullpath, 'w');
data = cellfun(@num2str, data, 'un', 0);

nrows = size(data, 1);
for row = 1:nrows
    fprintf(fid, fmt, data{row, :});
    if row ~= nrows
        fprintf(fid, '\n');
    end
end

end