
function writecell2delim(fullpath, data, delim, varargin)

% Write cell data to delimited text file

if numel(varargin) > 0
    header = varargin;
else
    header = [];
end

fmt = cell(1, size(data, 2)*2);
fmt(1:2:end) = {'%s'};
fmt(2:2:end-1) = {delim};
fmt{end} = '\n';
fmt = [fmt{:}];

data = cellfun(@num2str, data, 'UniformOutput', false)';

if ~isempty(header)
    header = sprintf('# %s\n', header{:});
end

fid = fopen(fullpath, 'w');
fprintf(fid, '%s', header, sprintf(fmt, data{:}));
fclose(fid);

end