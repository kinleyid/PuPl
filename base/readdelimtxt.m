
function out = readdelimtxt(txt, varargin)

if numel(varargin) == 1
    d = varargin{1};
else
    d = ',';
end

if numel(varargin) == 2
    q = varargin{2}; % Quote
else
    q = '"';
end

s = regexp(txt, sprintf('(^%s)|(%s%s)|(%s%s)|(%s$)', q, d, q, q, d, q), 'split'); % Get cell array
quoted = s(2:2:end);
if isempty(s{end})
    s(end) = [];
end
if isempty(s{1})
    unqs = 3;
else
    unqs = 1;
end
unquoted = s(unqs:2:end);

unquoted = cellfun(@(t) regexp(t, d, 'split'), unquoted, 'UniformOutput', false);
quoted = cellfun(@(t) {t}, quoted, 'UniformOutput', false);

s(unqs:2:end) = unquoted;
s(2:2:end) = quoted;

s = [s{:}];

% Get rid of extra delimiters
unquoted{1} = unquoted{1}(1:end-1);
unquoted{end} = unquoted{end}(2:end);
unquoted = cellfun(@(x) x(2:end-1), 'UniformOutput', false);

end