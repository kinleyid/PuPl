function EYE = eyefilter(EYE, varargin)

p = inputParser;
addParameter(p, 'filterType', []);
addParameter(p, 'n', []);
parse(p, varargin{:})

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

if isempty(p.Results.filterType) || isempty(p.Results.n)
    [filterType, n] = UI_getfilterinfo(EYE);
else
    filterType = p.Results.filterType;
    n = p.Results.n;
end

fprintf('Applying %s filter\n', filterType);
for dataIdx = 1:numel(EYE)
    fprintf('%s...', EYE(dataIdx).name); 
    EYE(dataIdx).data = applyeyefilter(EYE(dataIdx), filterType, n);
    fprintf('done\n');
end

end