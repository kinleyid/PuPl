
function EYE = pupl_normalize(EYE, varargin)

p = inputParser;
addParameter(p, 'center', []);
addParameter(p, 'scale', []);
parse(p, varargin{:});
unpack(p);

if isempty(center)
    t = 'Center by what quantity?';
    center = inputdlg(t, t, 1, {'`m'});
    if isempty(center)
        return
    else
        center = center{:};
    end
end

if isempty(scale)
    t = 'Scale by what quantity?';
    scale = inputdlg(t, t, 1, {'`s'});
    if isempty(scale)
        return
    else
        scale = scale{:};
    end
end

fprintf('Normalizing...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...\n', EYE(dataidx).name);
    for field = reshape(fieldnames(EYE(dataidx).diam), 1, [])
        fprintf('\t\t%s...', field{:});
        data = EYE(dataidx).diam.(field{:});
        data = (data - parsedatastr(center, data)) / parsedatastr(scale, data);
        EYE(dataidx).diam.(field{:}) = data;
        fprintf('done\n');
    end
    EYE(dataidx).history{end + 1} = getcallstr(p);
end
fprintf('Done\n');

end