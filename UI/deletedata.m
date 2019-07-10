function deletedata

global userInterface

UserData = get(userInterface, 'UserData');
global eyeData
dots = repmat({sprintf(' _ ')}, 1, numel(eyeData));
dots(UserData.activeEyeDataIdx) = {' > '};
rmidx = listdlgregexp(...
    'ListString', strcat(dots, {eyeData.name}),...
    'PromptString', 'Remove which?');
if isempty(rmidx)
    return
end
fprintf('Removing data...\n');
for curridx = reshape(rmidx, 1, [])
    fprintf('\t%s\n', eyeData(curridx).name);
end
fprintf('Done\n');
eyeData(rmidx) = [];
if isempty(eyeData)
    eyeData = struct([]);
end
UserData.activeEyeDataIdx(rmidx) = [];

set(userInterface, 'UserData', UserData);

end