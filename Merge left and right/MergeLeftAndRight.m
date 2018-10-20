
function MergeLeftAndRight

Question = 'Select the eye data files to merge the left and right streams of';
uiwait(msgbox(Question));
[Filenames,Path] = uigetfile('..\..\..\*.mat',...
    Question,...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

Question = 'Select a folder to same the eye data with merged streams to';
uiwait(msgbox(Question));
SaveTo = uigetdir([Path '\..'],...
              Question);

for Filename = Filenames
    MatData = load([Path '\' Filename{:}],'-mat');
    EYE = MatData.EYE;
    if isfield(EYE,'bins')
        for BinIdx = 1:numel(EYE.bins)
            EYE.bins(BinIdx).data.both = mean(cat(3,EYE.bins(BinIdx).data.left,EYE.bins(BinIdx).data.right),3,'omitnan');
        end
    end
    if isfield(EYE,'epochs')
        for EpochIdx = 1:numel(EYE.epochs)
            EYE.epochs(EpochIdx).data.both = mean(cat(3,EYE.epochs(EpochIdx).data.left,EYE.epochs(EpochIdx).data.right),3,'omitnan');
        end
    end
    if isfield(EYE,'data') % Unnecessary
        EYE.data.both = mean(cat(3,EYE.data.left,EYE.data.right),3,'omitnan');
    end
    fprintf('Saving [%s] to [%s]\n',EYE.name,SaveTo)
    save([SaveTo '\' EYE.name '.mat'],'EYE');
end