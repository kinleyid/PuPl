
function writecell2delim(fullpath, data, delim, varargin)

% Write cell data to delimited text file

if numel(varargin) > 0
    header = varargin;
else
    header = [];
end

ncols = size(data, 2);

data_fmt = cell(1, ncols);
% Check which columns need to be converted to numeric
for colidx = 1:ncols
    curr_col = data(2:end, colidx);
    if ~all(cellfun(@ischar, curr_col))
        curr_col(cellfun(@isempty, curr_col)) = {nan};
        as_str = num2str([curr_col{:}]);
        data(2:end, colidx) = regexp(as_str, '\s+', 'split');
        data_fmt{colidx} = '%s';
    else
        data_fmt{colidx} = '"%s"';
    end
end
full_fmt = cell(1, 2*ncols);
full_fmt(1:2:end) = data_fmt;
full_fmt(2:2:end) = {delim};
full_fmt(end) = {sprintf('\n')};
data_fmt = [full_fmt{:}];

col_fmt = cell(1, 2*ncols);
col_fmt(1:2:end) = {'%s'};
col_fmt(2:2:end) = {delim};
col_fmt(end) = {sprintf('\n')};
col_fmt = [col_fmt{:}];

data = data';

if ~isempty(header)
    header = sprintf('# %s\n', header{:});
end

cols = sprintf(col_fmt, data{:, 1});
contents = sprintf(data_fmt, data{:, 2:end});

fid = fopen(fullpath, 'w');
fprintf(fid, '%s', header, cols, contents);
fclose(fid);

end
