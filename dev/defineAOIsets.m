
function defineAOIsets(EYE, varargin)

p = inputParser;
addParameter(p, 'aoisets', []);
parse(p, varargin{:});

if isempty(p.Results.aoisets)
    aoisets = UI_getAOIsets(EYE);
    if isempty(aoisets)
        return
    end
else
    aoisets = p.Results.aoisets;
end

[EYE.aoiset] = deal(aoisets);

end