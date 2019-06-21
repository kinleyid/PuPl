
function EYE = defineAOIsets(EYE, varargin)

p = inputParser;
addParameter(p, 'aoisets', []);
addParameter(p, 'overwrite', []);
parse(p, varargin{:});

callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

if isempty(p.Results.overwrite)
    if any(arrayfun(@(x) ~isempty(x.aoiset), EYE))
        q = 'Overwrite existing trial sets?';
        a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
        switch a
            case 'Yes'
                overwrite = true;
            case 'No'
                overwrite = false;
            otherwise
                return
        end
    else
        overwrite = false;
    end
else
    overwrite = p.Results.overwrite;
end
callstr = sprintf('%s''overwrite'', %s)', all2str(overwrite));

if isempty(p.Results.aoisets)
    aoisets = UI_getsets(unique(mergefields(EYE, 'aoi', 'name')), 'AOI set');
    if isempty(aoisets)
        return
    end
else
    aoisets = p.Results.aoisets;
end
callstr = sprintf('%s''aoisets'', %s, ', all2str(aoisets));


if overwrite
    [EYE.aoiset] = deal([]);
end

[EYE.aoiset] = deal(aoisets);

fprintf('Adding AOI sets...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...\n', EYE(dataidx).name);
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
end

fprintf('Done\n');

end