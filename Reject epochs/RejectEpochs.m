
function RejectEpochs

uiwait(msgbox('Select the eye data to reject epochs from'));
[Filenames,Path] = uigetfile('..\..\..\*.mat',...
    'Select the eye data to reject epochs from',...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

uiwait(msgbox('Select a folder to save the eye data with rejection info to'));
SaveTo = uigetdir([Path '\..'],...
    'Select a folder to save the eye data with rejection info to');

Question = 'Above what percentage of missing data should epochs be rejected?';
Answer = inputdlg(Question,Question,1,{'10'});
RejThresh = str2double(Answer)/100;

for Filename = Filenames
    MatData = load([Path Filename{:}]);
    EYE = MatData.EYE;
    fprintf('Rejecting epochs from %s...\n',EYE.name);
    if ~isfield(EYE,'reject')
        EYE.reject = false(size(EYE.epochs));
    end
    if isempty(EYE.reject)
        EYE.reject = false(size(EYE.epochs));
    end
    for EpochIdx = 1:numel(EYE.epochs)
        AmountMissing = nnz(isnan(EYE.epochs(EpochIdx).data.left)) +...
                        nnz(isnan(EYE.epochs(EpochIdx).data.right));
        Total = 2*numel(EYE.epochs(EpochIdx).data.left);
        if AmountMissing/Total > RejThresh
            EYE.reject(EpochIdx) = true;
        end
    end
    fprintf('%d/%d (%.2f%%) epochs rejected for having more than %.2f%% missing points\n',nnz(EYE.reject),numel(EYE.reject),100*nnz(EYE.reject)/numel(EYE.reject),100*RejThresh);
    fprintf('Saving [%s] to [%s]\n\n',Filename{:},SaveTo)
    save([SaveTo '\' EYE.name '.mat'],'EYE');
end