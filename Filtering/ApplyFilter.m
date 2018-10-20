
function EYE = ApplyFilter(EYE,SmoothN,Type)

if isfield(EYE,'epochs')
    for EpochIdx = 1:numel(EYE.epochs)
        FieldNames = fieldnames(EYE.epochs(EpochIdx).data);
        for FieldName = FieldNames(:)'
            EYE.epochs(EpochIdx).data.(FieldName{:}) = FilterVector(EYE.epochs(EpochIdx).data.(FieldName{:}),SmoothN,Type);
        end
    end
end
if isfield(EYE,'bins')
    for BinIdx = 1:numel(EYE.bins)
        FieldNames = fieldnames(EYE.bins(EpochIdx).data);
        for FieldName = FieldNames(:)'
            for i = 1:size(EYE.data.bins(BinIdx).(FieldName{:}),1)
                EYE.bins(BinIdx).data.(FieldName{:})(i,:) = FilterVector(EYE.bins(BinIdx).data.(FieldName{:})(i,:),SmoothN,Type);
            end
        end
    end
end

FieldNames = fieldnames(EYE.data);
for FieldName = FieldNames(:)'
    EYE.data.(FieldName{:}) = FilterVector(EYE.data.(FieldName{:}),SmoothN,Type);
end

end

function OutVector = FilterVector(InVector,SmoothN,Type)

OutVector = NaN(size(InVector));

for i = 1:numel(InVector)
    sLat = max(i-SmoothN,1);
    eLat = min(i+SmoothN,numel(InVector));
    if ~isnan(InVector(i))
        if strcmp(Type,'Median')
            OutVector(i) = median(InVector(sLat:eLat),'omitnan');
        elseif strcmp(Type,'Mean')
            OutVector(i) = mean(InVector(sLat:eLat),'omitnan');
        elseif strcmp(Type,'Gaussian kernel')
            if SmoothN == 0
                OutVector(i) = InVector(i);
            else
                Gau = exp(-((((sLat:eLat)-i)/(SmoothN/3)).^2));
                OutVector(i) = sum(Gau(:).*InVector(sLat:eLat),'omitnan');
                OutVector(i) = OutVector(i)/sum(Gau(~isnan(InVector(sLat:eLat))));
            end
        end
    end
end

end