function Struct = ArrangeStructByField(Struct,Field)

[~,Idx] = sort([Struct.(Field)]);
Struct = Struct(Idx);