function currComponent = getcomponentbytag(currComponent, varargin)

% Get UI component by tag name
%   Inputs
% currComponent--graphics handle
% varargin--list of tag
%   Outputs
% currComponent--graphics handle

for i = 1:numel(varargin)
    currTags = arrayfun(@(x) x.Tag, currComponent.Children, 'un', 0);
    currComponent = currComponent.Children(strcmpi(currTags, varargin{i}));
end

end