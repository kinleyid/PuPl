
function s = stripmod(s)

% Strip modality

[~, s] = fileparts(s);
s(find(s == '_', 1, 'last'):end) = [];

end