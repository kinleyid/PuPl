
function out = getalltrialdata(EYE, varargin)

out = [];

for dataidx = 1:numel(EYE)
    out = [out gettrialdata(EYE(dataidx), [], varargin{:})];
end

end