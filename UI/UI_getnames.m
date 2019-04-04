function newNames = UI_getnames(varargin)

prompts = varargin{1};

if nargin == 1
    % Use single arg as old names
    oldNames = varargin{1};
elseif nargin == 2
    oldNames = varargin{2};
end

oldNames = cellstr(oldNames);
nOptsPerScreen = 10;

newNames = {};

for i = 1:nOptsPerScreen:length(oldNames)
    currPrompts = prompts(i:min(length(prompts), i+nOptsPerScreen-1));
    currNames = oldNames(i:min(length(oldNames), i+nOptsPerScreen-1));
    currNames = inputdlg(currPrompts,...
        'Which names should be used? (OK to go to next page)',...
        [1 100],...
        currNames);
    if isempty(currNames)
        newNames = [];
        return
    end
    newNames = cat(1, newNames(:), currNames(:));
end

end