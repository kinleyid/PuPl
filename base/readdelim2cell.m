
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
txt = fread(fid, 'uint8=>char')';
fclose(fid);

nrows = nnz(txt == eol);
if txt(end) ~= eol
    nrows = nrows + 1;
end

txt = strrep(txt, eol, d); % Get it all as one line, replacing newlines with delimiters
if any(txt == q) % Some text is quoted, do it the slow way
    qs = sprintf('(^%s)|(%s%s)', q, d, q);
    qe = sprintf('(%s%s)|(%s$)', q, d, q);
    qm = sprintf('%s%s%s', q, d, q);
    q_split = regexp(txt, sprintf('(%s)|(%s)|(%s)', qs, qm, qe), 'split'); % Get cell array
    q_idx = 2:2:numel(q_split);
    m = find(ismember(regexp(txt, qe), regexp(txt, qm)));
    for ii = m
        q_idx = [q_idx(1:ii) q_idx(ii)+1:2:numel(q_split)];
    end
    % Go from integer to logical index
    tmp = false(size(q_split));
    tmp(q_idx) = true;
    q_idx = tmp;
    % Edge cases of strings started or ended by quotes
    if isempty(q_split{end})
        q_split(end) = [];
        q_idx(end) = [];
    end
    if isempty(q_split{1})
        q_split(1) = [];
        q_idx(1) = [];
    end
    % Process quoted and unquoted text
    quoted = cellfun(@(t) {t}, q_split(q_idx), 'UniformOutput', false);
    unquoted = cellfun(@(t) regexp(t, d, 'split'), q_split(~q_idx), 'UniformOutput', false);
    % Put into big cell array
    q_split(q_idx) = quoted;
    q_split(~q_idx) = unquoted;
    % Get as shallow array
    txt = [q_split{:}];
else
    txt = regexp(txt, d, 'split'); % Get cell array
end

txt(end-mod(numel(txt), nrows)+1:end) = []; % Future source of bugs
ncols = numel(txt)/nrows;
out = reshape(txt, ncols, [])';

end