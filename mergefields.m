function currArray = mergefields(currArray, varargin)

% Recursively merges fields and their subfields to return a single array
%   Inputs
% currArray--struct array
% varargin--fields to access, in descending order
%   Outputs
% currArray--array of structs, cells, or numbers
%   Example:
% subStruct = struct('x', {1 2 3})
% superStruct = struct('sub', {subStruct subStruct})
% mergefields(superStruct, 'sub', 'x')
% >> 1 2 3 1 2 3

for i = 1:numel(varargin)
    currArray = struct(varargin{i},...
        arrayfun(@(x) reshape(x.(varargin{i}), 1, []), currArray, 'un', 0));
    if ischar(currArray(1).(varargin{i}))
        currArray = {currArray.(varargin{i})};
    else
        currArray = [currArray.(varargin{i})];
    end
end

end