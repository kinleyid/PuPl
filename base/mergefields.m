function array = mergefields(array, varargin)

% Recursively merge fields and their subfields to return a single array
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

for ii1 = 1:numel(varargin)
    curr_args = all2cell(varargin{ii1});
    sub_arrays = cell(size(curr_args));
    for ii2 = 1:numel(curr_args)
        field = curr_args{ii2};
        sub_arrays{ii2} = struct(field,... % Reshape the current field within the structure
            arrayfun(@(x) reshape(x.(field), 1, []), array, 'UniformOutput', false));
        sub_arrays{ii2} = {sub_arrays{ii2}.(field)};
        if ~any(cellfun(@ischar, sub_arrays{ii2})) % If no chars, can safely convert to a scalar array
            sub_arrays{ii2} = [sub_arrays{ii2}{:}];
        end
    end
    array = [sub_arrays{:}];
end

end