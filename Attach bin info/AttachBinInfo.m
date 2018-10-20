function AttachBinInfo

uiwait(msgbox('Select the processed eye data files for attaching bin info to'));
[Filenames,Path] = uigetfile('..\..\..\*.mat',...
    'Select the processed eye data files for adding bin info',...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

uiwait(msgbox('Select the folder to save the data with bin info to.'));
SaveTo = uigetdir([Path '\..'],'Select the folder to save the data with bin info to.');

MatData = load([Path '\' Filenames{1}]);
EYE = MatData.EYE;

EventTypes = unique({EYE.event.type});
Bins = {};

Correspondence = false(length(EventTypes),1);
i = 1;
while true
    Idx = listdlg('ListString',EventTypes,...
                  'PromptString',sprintf('Which events belong to bin %d?',i),...
                  'ListSize',[500 800]);
    Bins(i) = inputdlg(sprintf('Name of bin %d:',i));
    Correspondence(Idx,i) = true;
    Accepted = questdlg('Add another bin?', ...
        'Add another bin?', ...
        'Yes','No','Yes');
    if strcmp(Accepted,'No')
        break
    else
        i = i+1;
    end
end

fprintf('Putting data into bins...\n\n')
for FileIdx = 1:length(Filenames)
    MatData = load([Path '\' Filenames{FileIdx}]);
    EYE = MatData.EYE;
    [~,Name] = fileparts(Filenames{FileIdx});
    fprintf('%s:\n',Name);
    EYE.bins = [];
    for i = 1:length(Bins)
        EYE.bins(i).name = Bins{i};
        Idx = Correspondence(:,strcmp(Bins,Bins{i}));
        EYE.bins(i).events = EventTypes(Idx);
        Idx = ismember({EYE.event.type},EventTypes(Idx));
        Idx = Idx & ~EYE.reject;
        EYE.bins(i).data = squeeze(EYE.pupilLR(:,:,Idx))';
        fprintf('bin ''%s'' contains data from %d trials\n',EYE.bins(i).name,nnz(Idx))
    end
    fprintf('Saving...\n\n');
    save([SaveTo '\' Name '.mat'],'EYE');
end

fprintf('Done.\n');