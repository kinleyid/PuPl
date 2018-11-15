function binDescriptions = UI_getbindescriptions(EYE)

uniqueEpochNames = unique(mergefields(EYE, 'epoch', 'name'));

binDescriptions = struct([]);

q = sprintf('Simple trial merging?\n(one-to-one relationship\nbetween trial types and sets)');
a = questdlg(q, q, 'Yes', 'No', 'Yes');

if strcmp(a, 'Yes')
    binDescriptions = struct(...
        'name', uniqueEpochNames,...
        'epochs', uniqueEpochNames);
else
    binN = 1;

    while true
        name = inputdlg(sprintf('Name of set %d?', binN));
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
        binN = binN + 1;
    end
    
end