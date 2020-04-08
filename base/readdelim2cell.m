
function [out, header] = readdelim2cell(fullpath, delim, varargin)

if numel(varargin) == 1
    comment = varargin{1};
else
    comment = '#';
end

if numel(varargin) == 2
    q = varargin{2}; % Quote
else
    q = '"';
end

fid = fopen(fullpath);
% Read header
header = {};
while ~feof(fid)
    endofheader = ftell(fid);
    currline = fgetl(fid);
    if strcmp(currline(1:numel(comment)), comment)
        header{end + 1} = currline(numel(comment)+1:end);
    else
        break
    end
end

d = sprintf(delim);

% Determine number of columns
fseek(fid, endofheader, 'bof');
currline = fgetl(fid);
fseek(fid, endofheader, 'bof');
currline_long = fgets(fid);
eol = currline_long(length(currline)+1:end);

% Read raw
fseek(fid, endofheader, 'bof');
out = fread(fid, 'uint8=>char')';
fclose(fid);

nrows = nnz(out == eol);
if out(end) ~= eol
    nrows = nrows + 1;
end

out = strrep(out, eol, d); % Get it all as one line, replacing newlines with delimiters
if any(out == q) % Some text is quoted, do it the slow way
    quotesplit = regexp(out, sprintf('(^%s)|(%s%s)|(%s%s)|(%s$)', q, d, q, q, d, q), 'split'); % Get cell array
    
    quoted = quotesplit(2:2:end);
    if isempty(quotesplit{end})
        quotesplit(end) = [];
    end
    if isempty(quotesplit{1})
        unqs = 3;
    else
        unqs = 1;
    end
    unquoted = quotesplit(unqs:2:end);

    unquoted = cellfun(@(t) regexp(t, d, 'split'), unquoted, 'UniformOutput', false);
    quoted = cellfun(@(t) {t}, quoted, 'UniformOutput', false);

    quotesplit(unqs:2:end) = unquoted;
    quotesplit(2:2:end) = quoted;

    out = [quotesplit{:}];
else
    out = regexp(out, d, 'split'); % Get cell array
end

out(end-mod(numel(out), nrows)+1:end) = []; % Future source of bugs
ncols = numel(out)/nrows;
out = reshape(out, ncols, [])';

end