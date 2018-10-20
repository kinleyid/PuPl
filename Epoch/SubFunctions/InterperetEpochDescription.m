function EYE = InterperetEpochDescription(EYE,Epochs)

EYE.epochs = Epochs;
EYE.epochdata = [];
EYE.epochdata.pupilL = [];
EYE.epochdata.pupilR = [];

for EpochIdx = 1:length(Epochs)
    Epoch = Epochs(EpochIdx);
    if strcmp(Epoch.EpochType,'Length of time relative to events')
        EventInstances = find(strcmp({EYE.event.type},Epoch.EventType));
        EventLatency = EYE.event(EventInstances(Epoch.InstanceN)).latency;
        RelativeLatencies = [fliplr(0:-1:Epoch.Lims(1)*EYE.srate) 1:Epoch.Lims(2)*EYE.srate];
        Latencies = RelativeLatencies + EventLatency;
        EYE.epochdata(EpochIdx).pupilL = EYE.pupilL(Latencies);
        EYE.epochdata(EpochIdx).pupilR = EYE.pupilR(Latencies);
    elseif strcmp(Epoch.EpochType,'Between events')
        FirstEventInstances = find(strcmp({EYE.event.type},Epoch.EventType(1)));
        FirstEventLatency = EYE.event(FirstEventInstances(Epoch.InstanceN(1))).latency;
        SecondEventInstances = find(strcmp({EYE.event.type},Epoch.EventType(2)));
        SecondEventLatency = EYE.event(SecondEventInstances(Epoch.InstanceN(2))).latency;
        Latencies = (FirstEventLatency + Epoch.Lims(1)*EYE.srate):(SecondEventLatency + Epoch.Lims(2)*EYE.srate);
        EYE.epochdata(EpochIdx).pupilL = EYE.pupilL(Latencies);
        EYE.epochdata(EpochIdx).pupilR = EYE.pupilR(Latencies);
    elseif strcmp(Epoch.EpochType,'Between time points')
        Latencies = Epoch.Lims(1):Epoch.Lims(2);
        EYE.epochdata(EpochIdx).pupilL = EYE.pupilL(Latencies);
        EYE.epochdata(EpochIdx).pupilR = EYE.pupilR(Latencies);
    end
end

EYE.reject = [];

end