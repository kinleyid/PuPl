function EYE = AddLatencies(EYE)

Latencies = round(([EYE.event.time])*EYE.srate/1000) + 1;
Latencies = num2cell(Latencies);
[EYE.event(1:length(Latencies)).latency] = Latencies{:};
EYE.event = rmfield(EYE.event,'time');