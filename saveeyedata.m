function saveeyedata(EYE, saveDirectory, name)

if strcmp(saveDirectory, 'none')
    fprintf('Not saving %s eye data\n', name);
    return;
elseif isempty(saveDirectory)
    uiwait(msgbox(sprintf('Select a directory to save the %s eye data', name)));
    saveDirectory = uigetdir('.',...
        sprintf('Select a directory to save the %s eye data to', name));
    if saveDirectory == 0
        fprintf('Not saving %s eye data\n', name);
        return
    end
end

for currEYE = EYE(:)'
    save([saveDirectory '\' currEYE.name '.eyedata'], 'currEYE');
end

end