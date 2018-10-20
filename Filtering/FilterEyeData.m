function FilterEyeData
Question = 'Select the eye data for filtering';
uiwait(msgbox(Question));
[Filenames,Path] = uigetfile('..\..\..\*.mat',...
    Question,...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

uiwait(msgbox('Select a folder to save the filtered eye data to'));
SaveTo = uigetdir([Path '\..'],...
    'Select a folder to save the filtered eye data to');

FilterTypes = {'Median' 'Mean' 'Gaussian kernel'};

[SmoothN,Type] = GetFilterInfo(Path,Filenames,FilterTypes);

for Filename = Filenames
    MatData = load([Path Filename{:}]);
    EYE = MatData.EYE;
    EYE = ApplyFilter(EYE,SmoothN,Type);
    fprintf('Saving [%s] to [%s]\n',Filename{:},SaveTo)
    save([SaveTo '\' EYE.name '.mat'],'EYE');
end