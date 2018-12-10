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
    [filterType, n] = UI_getfilterinfo;
    if isempty(filterType)
        return
    end
else
    filterType = p.Results.filterType;
    n = p.Results.n;
end

fprintf('Applying %s filter of %d points on either side\n', filterType, n);
for dataIdx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataIdx).name); 
    EYE(dataIdx).diam = applyeyefilter(EYE(dataIdx), filterType, n);
    fprintf('done\n');
end

end

function [filterType, smoothN] = UI_getfilterinfo

filterOptions = {'Median' 'Mean' 'Gaussian kernel'};

q = 'Which type of moving average?';
filterType = questdlg(q, q, filterOptions{:}, 'Median');
if isempty(filterType)
    smoothN = [];
    return
end
q = 'Average of how many points on either side?';
smoothN = str2double(inputdlg(q, q, 1, {'8'}));

end

function tempData = applyeyefilter(EYE, filterType, smoothN)

%  Inputs
% EYE--single struct, not array
% filterType
% smoothN

if strcmpi(filterType, 'Median')
    filtfunc = @eyemedian;
elseif strcmpi(filterType, 'Mean')
    filtfunc = @eyemean;
elseif strcmpi(filterType, 'Gaussian kernel')
    filtfunc = @gaussiankernel;
end

[permData, tempData] = deal(EYE.diam);

for stream = reshape(fieldnames(tempData), 1, [])
    for latIdx = 1:length(permData.left)
        if ~isnan(tempData.(stream{:})(latIdx))
            sLat = max(latIdx-smoothN,1);
            eLat = min(latIdx+smoothN,length(tempData.(stream{:})));
            tempData.(stream{:})(latIdx) = filtfunc(permData.(stream{:})(sLat:eLat),...
                sLat, eLat, latIdx);
        end
    end
end

end

function y = eyemean(v, varargin)

y = mean(v, 'omitnan');

end

function y = eyemedian(v, varargin)

y = median(v, 'omitnan');

end

function y = gaussiankernel(v, sLat, eLat, latIdx)

if numel(v) > 1
    x = (sLat:eLat) - latIdx;
    s = max(eLat - latIdx, latIdx - sLat);
    g = exp(-((((x)/(s/3)).^2)));
    y = sum(g(:) .* v(:), 'omitnan');
    y = y / sum(g(~isnan(v)));
end

end