
function writecell(fullpath, data, delim, varargin)

% Write cell data to delimited text file

if numel(varargin) > 0
    header = varargin;
else
    header = [];
end

fmt = cell(1, size(data, 2)*2 - 1);
fmt(1:2:end) = {'%s'};
fmt(2:2:end-1) = {delim};
fmt = [fmt{:}];

fid = fopen(fullpath, 'w');
data = cellfun(@num2str, data, 'un', 0);

if ~isempty(header)
    fprintf(fid, '# %s\n', header{:});
end

nrows = size(data, 1);
for row = 1:nrows
    fprintf(fid, fmt, data{row, :});
    if row ~= nrows
        fprintf(fid, '\n');
    end
end

fclose(fid);

end