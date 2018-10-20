function EYE = UseEpochDescriptions(EYE,EpochDescriptions,RejThresh)

EpochTypes = {'Using single events' 'Using pairs of events'};
EYE.epochs = EpochDescriptions;
fprintf('Now epoching [%s]\n',EYE.name);

if ~isfield(EYE,'reject')
    EYE.reject = false(size(EYE.epochs));
end
if isempty(EYE.reject)
    EYE.reject = false(size(EYE.epochs));
end

for EpochDescriptionIdx = 1:numel(EpochDescriptions)
    EpochDescription = EpochDescriptions(EpochDescriptionIdx);
    if strcmp(EpochDescription.type,EpochTypes{1})
        Instances = find(strcmp({EYE.event.type},EpochDescription.info.event));
        EventIdx = Instances(EpochDescription.info.instanceN);
        EventLatency = EYE.event(EventIdx).latency;
        Lims = round(EpochDescription.info.lims*EYE.srate);
        Latencies = (EventLatency+Lims(1)):(EventLatency+Lims(2));
    elseif strcmp(EpochDescription.type,EpochTypes{2})
        Instances1 = find(strcmp({EYE.event.type},EpochDescription.info.event(1)));
        EventIdx1 = Instances1(EpochDescription.info.instanceN(1));
        Instances2 = find(strcmp({EYE.event.type},EpochDescription.info.event(2)));
        EventIdx2 = Instances2(EpochDescription.info.instanceN(2));
        EventLatencies = [EYE.event(EventIdx1).latency EYE.event(EventIdx2).latency];
        Lims = EpochDescription.info.lims*EYE.srate;
        Latencies = (EventLatencies(1)+Lims(1)):(EventLatencies(2)+Lims(2));
    end
    FieldNames = fieldnames(EYE.data);
    TotalMissing = 0;
    for FieldName = FieldNames(:)'
        EYE.epochs(EpochDescriptionIdx).data.(FieldName{:}) = EYE.data.(FieldName{:})(Latencies);
        EYE.epochs(EpochDescriptionIdx).latencies = Latencies;
        if isfield(EYE,'urdata')
            TotalMissing = TotalMissing + nnz(isNaN(EYE.urdata.(FieldName{:})(Latencies)));
        else
            TotalMissing = TotalMissing + nnz(isNaN(EYE.data.(FieldName{:})(Latencies)));
        end
        Total = Total + numel(Latencies);
    end
    if TotalMissing/Total > RejThresh
        EYE.reject(EpochDescriptionIdx) = true;
    end
end

fprintf('Successfully created %d epochs\n',numel(EYE.epochs))

end