function EYE = eyefilter(EYE, varargin)

p = inputParser;
addParameter(p, 'filterType', []);
addParameter(p, 'n', []);
addParameter(p, 'saveTo', []);
parse(p, varargin{:})

if isempty(p.Results.filterType) || isempty(p.Results.n)
    [filterType, n] = UI_getfilterinfo(EYE);
else
    filterType = p.Results.filterType;
    n = p.Results.n;
end

for dataIdx = 1:numel(EYE)
    EYE(dataIdx).data = applyeyefilter(EYE(dataIdx), filterType, n);
end

saveeyedata(EYE, p.Results.saveTo, 'filtered');