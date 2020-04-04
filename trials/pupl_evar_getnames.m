
function out = pupl_evar_getnames(events)

defaults = {'name' 'time' 'uniqid'};
fields = fieldnames(events);
out = fields(~ismember(fields, defaults));
out = out(:)';

end