function Struct1 = AttachEvents(Struct1,Struct2,TimeParams,EventsToAttach,NamesToUse)

Times = [];
Names = [];
for i = 1:length(EventsToAttach)    
    Struct2Times = [Struct2.event(strcmp({Struct2.event.type},EventsToAttach(i))).time];
    CurrTimes = num2cell([Struct2Times(:) ones(size(Struct2Times(:)))]*TimeParams);
    Times = [Times; CurrTimes(:)];
    CurrNames = repmat(NamesToUse(i),size(Struct2Times));
    Names = [Names; CurrNames(:)];
end

TempEvent = [];
[TempEvent(1:length(Times)).time] = Times{:};
[TempEvent(1:length(Names)).type] = Names{:};

Struct1.event = Struct1.event(:);
TempEvent = TempEvent(:);
Struct1.event = cat(1,Struct1.event,TempEvent);
Struct1.event = ArrangeStructByField(Struct1.event,'time');