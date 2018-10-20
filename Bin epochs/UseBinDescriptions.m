
function EYE = UseBinDescriptions(EYE,BinDescriptions)

Bins = [];

for BinDescription = BinDescriptions
    Bins(numel(Bins)+1).description = BinDescription;
    Bins(end).data.left = [];
    Bins(end).data.right = [];
    for Epoch = BinDescription.epochs
        EpochIdx = arrayfun(@isequal,CopyEventsAndInstanceNs(EYE.epochs),repmat(Epoch,size(EYE.epochs)));
        if EYE.reject(EpochIdx)
            continue
        end
        FieldNames = fieldnames(EYE.epochs(EpochIdx).data);
        for FieldName = FieldNames(:)'
            try
                Bins(end).data.(FieldName{:}) = cat(1,Bins(end).data.(FieldName{:}),EYE.epochs(EpochIdx).data.(FieldName{:})(:)');
            catch
                Question = sprintf('It looks like you''re trying to put epochs of different lengths in bin [%s].\nPadding the ENDS of the shorter epochs with NaNs.',Bins(end).description.name);
                Answer = questdlg(Question,Question,'Ok','Not ok (abort)','Not ok (abort)');
                if strcmp(Answer,'Not ok (abort)') || isempty(Answer)
                    error('Program terminated for a specific reason');
                else
                    if size(Bins(end).data.(FieldName{:}),2) > size(EYE.epochs(EpochIdx).data.(FieldName{:})(:)',2)
                        TmpData = cat(1,EYE.epochs(EpochIdx).data.(FieldName{:})(:)',NaN(1,size(Bins(end).data.(FieldName{:}),2)-size(EYE.epochs(EpochIdx).data.(FieldName{:})(:)',2)));
                        Bins(end).data.(FieldName{:}) = cat(1,Bins(end).data.(FieldName{:}),TmpData);
                    else
                        NewBinData = cat(2,Bins(end).data.(FieldName{:}),NaN(size(Bins(end).data.(FieldName{:}),1),size(EYE.epochs(EpochIdx).data.(FieldName{:})(:)',2) - size(Bins(end).data.(FieldName{:}),2)));
                        Bins(end).data.(FieldName{:}) = cat(1,NewBinData,EYE.epochs(EpochIdx).data.(FieldName{:})(:)');
                    end
                end
            end
        end
    end
end

EYE.bins = Bins;

end

function EpochInfo = CopyEventsAndInstanceNs(Epochs)

EpochInfo = [];
for Epoch = Epochs
    EpochInfo(numel(EpochInfo)+1).type = Epoch.type;
    EpochInfo(end).info.event = Epoch.info.event;
    EpochInfo(end).info.instanceN = Epoch.info.instanceN;
end
    
end