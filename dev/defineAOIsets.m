
function defineAOIsets(EYE, varargin)

p = inputParser;
addParameter(p, 'aoisets', []);
parse(p, varargin{:});

callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

if isempty(p.Results.aoisets)
    aoisets = UI_getsets(unique(mergefields(EYE, 'aoi', 'name')), 'AOI set');
    if isempty(aoisets)
        return
    end
else
    aoisets = p.Results.aoisets;
end

callstr = sprintf('%s''aoisets'', %s)', all2str(aoisets));

[EYE.aoiset] = deal(aoisets);

for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    for aoisetidx = 1:numel(EYE(dataidx).aoiset)
        isinaoiset = ismember({EYE(dataidx).aoi.name}, EYE(dataidx).aoiset(aoisetidx));
        
    end
end

fprintf('Done\n');

end