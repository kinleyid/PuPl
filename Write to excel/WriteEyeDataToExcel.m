function WriteEyeDataToExcel

uiwait(msgbox('Select files to get data from'));
[Filenames,Path] = uigetfile('..\..\..\*.mat','Select a file to get data from');
Filenames = cellstr(Filenames);

uiwait(msgbox('Select the excel file to save the data as'));
[ExcelFile,ExcelPath] = uiputfile([Path '\..\*.xslx'],'Select the excel file to save the data as');

Conditions = [];
Bins = [];
CorrectionMethods = [];
Data = [];
for Filename = Filenames
    MatData = load([Path '\' Filename{:}]);
    EYE = MatData.EYE;
    for i = 1:length(EYE.bins)
        Data = cat(1,Data,EYE.bins(i).data);
        Conditions = cat(1,Conditions,repmat({EYE.cond},size(EYE.bins(i).data,1),1));
        Bins = cat(1,Bins,repmat({EYE.bins(i).name},size(EYE.bins(i).data,1),1));
        CorrectionMethods = cat(1,CorrectionMethods,repmat({EYE.epochinfo.correction},size(EYE.bins(i).data,1),1));
    end
end
T = [Conditions Bins CorrectionMethods num2cell(Data)];
T = cat(1,[{'Condition' 'Bin' 'Correction method'} arrayfun(@(x) [num2str(x) 's'], EYE.epochinfo.times, 'un',0)],T);

xlswrite([ExcelPath ExcelFile],T)