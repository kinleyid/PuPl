function saveeyedata(varargin)

EYE = varargin{1};
if nargin >= 2
    saveDirectory = varargin{2};
else
    saveDirectory = [];
end

names = {};

if nargin >= 3
    names(1) = varargin{3};
else
    names(1) = '';
end

if nargin >= 4
    names(2) = varargin{4};
else
    names(2) = '';
end

name = sprintf('%s eye data %s', names{:});

if strcmp(saveDirectory, 'none')
    fprintf('Not saving %s\n', name);
    return;
elseif isempty(saveDirectory)
    uiwait(msgbox(sprintf('Save %s', name)));
    saveDirectory = uigetdir('.',...
        sprintf('Save %s', name));
    if saveDirectory == 0
        fprintf('Not saving %s\n', name);
        return
    end
end

for currEYE = EYE(:)'
    save([saveDirectory '\' currEYE.name '.eyedata'], 'currEYE');
end

end