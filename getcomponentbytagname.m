function currComponent = getcomponentbytagname(currComponent, varargin)

% Get component by tag name

for i = 1:numel(varargin)
    currTags = arrayfun(@(x) x.Tag, currComponent.Children, 'un', 0);
    currComponent = currComponent.Children(strcmpi(currTags, varargin{i}));
end

end