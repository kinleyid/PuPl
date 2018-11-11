function binDescriptions = UI_getbindescriptions(EYE)

% Get unique event names
allEpochNames = {};
for dataIdx = 1:numel(EYE)
    allEpochNames = [allEpochNames unique({EYE(dataIdx).epoch.name})];
end
uniqueEpochNames = unique(allEpochNames);

binDescriptions = [];

while true
    q = 'Add a bin?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        break
    else
        name = inputdlg('Name of bin?');
        epochIdx = listdlg('PromptString', 'Which epochs?',...
            'ListString', uniqueEpochNames);
        binDescriptions = [binDescriptions...
            struct('name', name,...
                'epochs', uniqueEpochNames(epochIdx))];
    end
end