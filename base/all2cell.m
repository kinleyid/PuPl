
function out = all2cell(in)

if ischar(in)
    out = {in};
elseif isnumeric(in)
    out = {};
    for ii = 1:numel(in)
        out{ii} = in(ii);
    end
elseif iscell(in)
    out = in;
end