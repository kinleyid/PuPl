
function BinEpochs

uiwait(msgbox('Select the epoched eye data for binning'));
[Filenames,Path] = uigetfile('..\..\..\..\*.mat',...
    'Select the epoched eye data for binning',...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

uiwait(msgbox('Select a folder to save the binned eye data to'));
SaveTo = uigetdir([Path '\..'],...
    'Select a folder to save the binned eye data to');

Question = 'Bin each file the same way?';
Answer = questdlg(Question,Question,'Yes','No','Yes');
if strcmp(Answer,'Yes')
    MatData = load([Path Filenames{1}]);
    EYE = MatData.EYE;
    BinDescriptions = GetBinDescriptions(EYE);
    SameForEach = true;
else
    SameForEach = false;
end

for Filename = Filenames
    MatData = load([Path Filenames{1}]);
    EYE = MatData.EYE;
    if ~SameForEach
        BinDescriptions = GetBinDescriptions(EYE);
    end
    EYE = UseBinDescriptions(EYE,BinDescriptions);
    fprintf('Saving [%s] to [%s]\n',Filename{:},SaveTo)
    save([SaveTo '\' EYE.name '.mat'],'EYE');
end