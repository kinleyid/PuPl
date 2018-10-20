function EYE = ApplyBaselineCorrection(EYE,BaselineDescriptions)

BaselineTypes = {'Using single events' 'Using pairs of events' 'Using epochs'};
CorrectionTypes = {'Compute percent dilation from baseline average' 'Subtract baseline average' 'No baseline correction'};

for BaselineDescription = BaselineDescriptions
    if strcmp(BaselineDescription.type,BaselineTypes{1})
        Instances = find(strcmp({EYE.event.type},BaselineDescription.info.event));
        EventIdx = Instances(BaselineDescription.info.instanceN);
        EventLatency = EYE.event(EventIdx).latency;
        Lims = round(BaselineDescription.info.lims*EYE.srate);
        Latencies = (EventLatency+Lims(1)):(EventLatency+Lims(2));
        FieldNames = fieldnames(EYE.data);
        for FieldName = FieldNames(:)'
            Baseline = mean(EYE.data.(FieldName{:})(Latencies),'omitnan');
            for EpochDescription = BaselineDescription.epochs
                EpochIdx = arrayfun(@isequal,CopyEventsAndInstanceNs(EYE.epochs),repmat(EpochDescription,size(EYE.epochs)));
                if strcmp(BaselineDescription.correction,CorrectionTypes{1})
                    EYE.epochs(EpochIdx).data.(FieldName{:}) = EYE.epochs(EpochIdx).data.(FieldName{:})/Baseline;
                elseif strcmp(BaselineDescription.correction,CorrectionTypes{2})
                    EYE.epochs(EpochIdx).data.(FieldName{:}) = EYE.epochs(EpochIdx).data.(FieldName{:}) - Baseline;
                end
            end
        end
    elseif strcmp(BaselineDescription.type,BaselineTypes{2})
        Instances1 = find(strcmp({EYE.event.type},BaselineDescription.info.event(1)));
        EventIdx1 = Instances1(BaselineDescription.info.instanceN(1));
        Instances2 = find(strcmp({EYE.event.type},BaselineDescription.info.event(2)));
        EventIdx2 = Instances2(BaselineDescription.info.instanceN(2));
        EventLatencies = [EYE.event(EventIdx1).latency EYE.event(EventIdx2).latency];
        Lims = BaselineDescription.info.lims*EYE.srate;
        Latencies = (EventLatencies(1)+Lims(1)):(EventLatencies(2)+Lims(2));
        FieldNames = fieldnames(EYE.data);
        for FieldName = FieldNames(:)'
            Baseline = mean(EYE.data.(FieldName{:})(Latencies),'omitnan');
            for EpochDescription = BaselineDescription.epochs
                EpochIdx = arrayfun(@isequal,CopyEventsAndInstanceNs(EYE.epochs),repmat(EpochDescription,size(EYE.epochs)));
                if strcmp(BaselineDescription.correction,CorrectionTypes{1})
                    EYE.epochs(EpochIdx).data.(FieldName{:}) = EYE.epochs(EpochIdx).data.(FieldName{:})/Baseline;
                elseif strcmp(BaselineDescription.correction,CorrectionTypes{2})
                    EYE.epochs(EpochIdx).data.(FieldName{:}) = EYE.epochs(EpochIdx).data.(FieldName{:}) - Baseline;
                end
            end
        end
    elseif strcmp(BaselineDescription.type,BaselineTypes{3})
        Lims = round(BaselineDescription.info.lims*EYE.srate);
        for EpochDescription = BaselineDescription.epochs
            EpochIdx = arrayfun(@isequal,CopyEventsAndInstanceNs(EYE.epochs),repmat(EpochDescription,size(EYE.epochs)));
            if strcmp(BaselineDescription.info.refpoints,'Start')
                Latencies = (Lims(1)+EYE.epochs(EpochIdx).latencies(1)):(Lims(2)+EYE.epochs(EpochIdx).latencies(1));
            elseif strcmp(BaselineDescription.info.refpoints,'End')
                Latencies = (Lims(1)+EYE.epochs(EpochIdx).latencies(end)):(Lims(2)+EYE.epochs(EpochIdx).latencies(end));
            elseif strcmp(BaselineDescription.info.refpoints,'Both')
                Latencies = (Lims(1)+EYE.epochs(EpochIdx).latencies(1)):(Lims(2)+EYE.epochs(EpochIdx).latencies(end));
            end
            FieldNames = fieldnames(EYE.data);
            for FieldName = FieldNames(:)'
                Baseline = mean(EYE.data.(FieldName{:})(Latencies),'omitnan');
                if strcmp(BaselineDescription.correction,CorrectionTypes{1})
                    EYE.epochs(EpochIdx).data.(FieldName{:}) = EYE.epochs(EpochIdx).data.(FieldName{:})/Baseline;
                elseif strcmp(BaselineDescription.correction,CorrectionTypes{2})
                    EYE.epochs(EpochIdx).data.(FieldName{:}) = EYE.epochs(EpochIdx).data.(FieldName{:}) - Baseline;
                end
            end
        end
    end
end

end

function EpochInfo = CopyEventsAndInstanceNs(Epochs)

EpochInfo = [];
for Epoch = Epochs
    EpochInfo(numel(EpochInfo)+1).type = Epoch.type;
    EpochInfo(end).info.event = Epoch.info.event;
    EpochInfo(end).info.instanceN = Epoch.info.instanceN;
end
    
end