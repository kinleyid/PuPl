function EYE = ApplyBaselineCorrection(EYE,Baselines,Correction)

for BaselineIdx = 1:numel(Baselines)
    if strcmp(Baselines(BaselineIdx).Type,'Time limits relative to an event')
        
    elseif strcmp(Baselines(BaselineIdx).Type,'Between events')
        
    elseif strcmp(Baselines(BaselineIdx).Type,'Time limits relative to an epoch')
        for EpochIdx = 1:numel(EYE.epochs)
            if isequal(EYE.epochs(EpochIdx).EventType,Baselines(BaselineIdx).Info.EpochTypes)
                EventInstances = strcmp({EYE.event.type},EYE.epochs(EpochIdx).EventType);
                CurrInstance = EventInstances(EYE.epochs(EpochIdx)
                Latency = EYE.epochs(EpochIdx).EventType
            end
        end
    end
end
        