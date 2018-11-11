function EYE = mergelr(EYE, varargin)

p = inputParser;
addParameter(p, 'saveTo', []);
parse(p, varargin{:});

for dataIdx = 1:numel(EYE)
    EYE.data.both = mean([
        EYE.data.left
        EYE.data.right], 'omitnan');
end

saveeyedata(EYE, p.Results.saveTo, 'stream-merged');

end