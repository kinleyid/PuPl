
function EYE = pupl_normalize(EYE, varargin)

p = inputParser;
addParameter(p, 'center', []);
addParameter(p, 'scale', []);
parse(p, varargin{:});

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);
if isempty(p.Results.center)
    q = 'Subtract average diameter?';
    center = lower(questdlg(q,q,'Median','Mean','None','None'));
    if isempty(center)
        return
    end
else
    center = p.Results.center;
end
callStr = sprintf('%s''center'', %s, ', callStr, all2str(center));

if isempty(p.Results.scale)
    optnames = {'Divide by median'
        'Divide by mean'
        'Divide by std.dev'
        'None'};
    opts = {'median'
        'mean'
        'stdev'
        'none'};
    optidx = listdlg('PromptString', 'Scale diameter?',...
        'ListString', optnames);
    if isempty(optidx)
        return
    end
    scale = opts{optidx};
else
    scale = p.Result.scale;
end
callStr = sprintf('%s''scale'', %s)', callStr, all2str(scale));

switch center
    case 'mean'
        centerfunc = @(x) x - mean(x, 'omitnan');
    case 'median'
        centerfunc = @(x) x - median(x, 'omitnan');
    otherwise
        centerfunc = @(x) x;
end
switch scale
    case 'mean'
        scalefunc = @(x) x / mean(x, 'omitnan');
    case 'median'
        scalefunc = @(x) x / median(x, 'omitnan');
    case 'stdev'
        scalefunc = @(x) x / std(x, 'omitnan');
    otherwise
        scalefunc = @(x) x;
end

fprintf('Normalizing data:\nCentering by <%s> and scaling by <%s>...\n', center, scale)
for dataidx = 1:numel(EYE)
    fprintf('\t%s\n', EYE(dataidx).name);
    for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
        EYE(dataidx).diam.(stream{:}) = centerfunc(EYE(dataidx).diam.(stream{:}));
        EYE(dataidx).diam.(stream{:}) = scalefunc(EYE(dataidx).diam.(stream{:}));
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
end
fprintf('Done\n');

end