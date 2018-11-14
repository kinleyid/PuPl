function structure = mergefields(structure, varargin)

%   Inputs
% structure--struct array
% field1, field2, etc.--fields to access. varargin{1} is the field that's merged

for i = 1:numel(varargin)
    structure = struct(varargin{i},...
        arrayfun(@(x) reshape(x.(varargin{i}), 1, []), structure, 'un', 0));
    if isstruct(structure(1).(varargin{i})) || isnumeric(structure(1).(varargin{i}))
        structure = [structure.(varargin{i})];
    elseif ischar(structure(1).(varargin{i}))
        structure = {structure.(varargin{i})};
    end
end

end