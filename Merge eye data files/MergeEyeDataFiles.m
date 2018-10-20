
function MergeEyeDataFiles

while true
    
    Question = 'Create a new merged file?';
    Answer = questdlg(Question,Question,'Yes','No','Yes');
    if strcmp(Answer,'No') || isempty(Answer)
        break
    else
        Question = 'Name of merged file?';
        Name = inputdlg(Question,Question,1);
        if isempty(Name)
            break
        end
        Name = Name{:};
        Question = sprintf('Select the files to merge into [%s]',Name);
        uiwait(msgbox(Question));
        [Filenames,Path] = uigetfile('..\..\..\*.mat',...
            Question,...
            'MultiSelect','on');
        Filenames = cellstr(Filenames);
        Question = sprintf('Select a folder to save [%s] to',Name);
        uiwait(msgbox(Question));
        SaveTo = uigetdir([Path '\..'],...
            Question);
        MERGED = [];
        MERGED.name = Name;
        % Add bins from first file
        MatData = load([Path '\' Filenames{1}],'-mat');
        EYE = MatData.EYE;
        MERGED.srate = EYE.srate;
        MERGED.bins = EYE.bins;
        for Filename = Filenames(2:end)
            MatData = load([Path '\' Filename{:}],'-mat');
            EYE = MatData.EYE;
            if MERGED.srate ~= EYE.srate
                error('Unequal sample rates')
            end
            for BinIdx = 1:numel(EYE.bins)
                MergedBins = [MERGED.bins.description];
                MatchIdx = strcmp({MergedBins.name},EYE.bins(BinIdx).description.name);
                if ~any(MatchIdx)
                    Question = sprintf('[%s] does not have any of the bins that [%s] does',Filename{:},Filenames{1});
                    Answer = questdlg(Question,Question,'Ok','Abort','Ok');
                    if strcmp(Answer,'Abort') || isempty(Answer)
                        error(Question)
                    end
                else
                    try
                        MERGED.bins(MatchIdx).data.left = cat(1,MERGED.bins(MatchIdx).data.left,EYE.bins(BinIdx).data.left);
                        MERGED.bins(MatchIdx).data.right = cat(1,MERGED.bins(MatchIdx).data.right,EYE.bins(BinIdx).data.right);
                    catch
                        Question = sprintf('The length of the data in bin [%s] of [%s] doesn''t match the length of data in that bin in the merged file. Will abort.',EYE.bins(BinIdx).description.name,Filename{:});
                        uiwait(msgbox(Question));
                        error(Question)
                    end
                end
            end
        end
        EYE = MERGED;
        fprintf('Saving [%s] to [%s]\n',MERGED.name,SaveTo)
        save([SaveTo '\' MERGED.name '.mat'],'EYE');
    end
    
end