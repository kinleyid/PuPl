function EpochEyeData
uiwait(msgbox('Select the aligned eye data files for epoching'));
[Filenames,Path] = uigetfile('..\..\..\*.mat',...
    'Select the aligned eye data files for epoching',...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

uiwait(msgbox('Select a folder to save the epoched eye data to'));
SaveTo = uigetdir([Path '\..'],...
                  'Select a folder to save the epoched eye data to');

cd SubFunctions

if length(Filenames) > 1
    Answer = questdlg('Epoch the same way for each file?','Epoch the same way for each file?','Yes','No','No');
    if strcmp(Answer,'Yes')
        SameForEach = true;
        MatData = load([Path '\' Filenames{1}],'-mat');
        EYE = MatData.EYE;
        Epochs = GetEpochDescription(EYE);
    else
        SameForEach = false;
    end
end


for FileIdx = 1:length(Filenames)
    MatData = load([Path '\' Filenames{FileIdx}],'-mat');
    EYE = MatData.EYE;
    [~,Name] = fileparts(Filenames{FileIdx});
    if ~SameForEach
        uiwait(msgbox(sprintf('Now epoching %s',Name)));
        Epochs = GetEpochDescription(EYE);
    end
    EYE = InterperetEpochDescription(EYE,Epochs);
    EYE.name = Name;
    save([SaveTo '\' Name '.mat'],'EYE');
    fprintf('Saving to %s\n',SaveTo)
end