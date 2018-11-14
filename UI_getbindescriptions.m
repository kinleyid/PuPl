function binDescriptions = UI_getbindescriptions(EYE)

uniqueEpochNames = unique(mergefields(EYE, 'epoch', 'name'));

binDescriptions = struct([]);

while true
    name = inputdlg('Name of bin?');
    epochIdx = listdlg('PromptString', 'Which epochs?',...
        'ListString', uniqueEpochNames);
    binDescriptions = [binDescriptions...
        struct('name', name,...
            'epochs', {uniqueEpochNames(epochIdx)})];
    q = 'Add another bin?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        break
    end
end