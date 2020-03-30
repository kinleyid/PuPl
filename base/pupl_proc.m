
function EYE = pupl_proc(EYE, func, varargin)

if isempty(varargin)
    fields1 = {'pupil'};
else
    if strcmp(varargin{1}, 'all')
        fields1 = {'pupil' 'gaze'};
    else
        fields1 = varargin;
    end
end

for field1 = fields1
    for field2 = reshape(fieldnames(EYE.(field1{:})), 1, [])
        EYE.(field1{:}).(field2{:}) = func(EYE.(field1{:}).(field2{:}));
    end
end

end