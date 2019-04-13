function EYE = eyefilter(EYE, varargin)

p = inputParser;
addParameter(p, 'dataType', []);
addParameter(p, 'filterType', []);
addParameter(p, 'hwidth', []);
parse(p, varargin{:})

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);
if isempty(p.Results.dataType)
    q = 'Filter which data?';
    dataType = questdlg(q, q, 'Dilation', 'Gaze', 'Dilation');
    if isempty(dataType)
        return
    end
else
    dataType = p.Results.dataType;
end
callStr = sprintf('%s''dataType'', %s, ', callStr, all2str(dataType));

if isempty(p.Results.filterType) || isempty(p.Results.hwidth)
    [filterType, hwidth] = UI_getfilterinfo;
    if isempty(filterType)
        return
    end
    hwidth = hwidth{:};
else
    filterType = p.Results.filterType;
    hwidth = p.Results.hwidth;
end
callStr = sprintf('%s''filterType'', %s, ''hwidth'', %s)', callStr, all2str(filterType), all2str(hwidth));

fprintf('Applying %s filter of %s on either side\n', filterType, hwidth);
for dataidx = 1:numel(EYE)
    currN = round(parsetimestr(hwidth, EYE(dataidx).srate)*EYE(dataidx).srate);
    fprintf('\t%s: filter width is %d data points\n', EYE(dataidx).name, currN*2 + 1); 
    switch dataType
        case 'Dilation'
            field = 'diam';
        case 'Gaze'
            field = 'gaze';
    end
    EYE(dataidx).(field) = applyeyefilter(EYE(dataidx), dataType, filterType, currN);
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
end
fprintf('done\n');

end

function [filterType, smoothN] = UI_getfilterinfo

filterOptions = {'Median' 'Mean' 'Gaussian kernel'};

q = 'Which type of moving average?';
filterType = questdlg(q, q, filterOptions{:}, 'Median');
if isempty(filterType)
    smoothN = [];
    return
end
q = 'Average of how long on either side?';
smoothN = inputdlg(q, q, 1, {'100ms'});
if isempty(smoothN)
    filterType = [];
    return
end

end

function tempData = applyeyefilter(EYE, dataType, filterType, smoothN)

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

switch dataType
    case 'Dilation'
        [permData, tempData] = deal(EYE.diam);
    case 'Gaze'
        [permData, tempData] = deal(EYE.gaze);
end

for stream = reshape(fieldnames(tempData), 1, [])
    for latIdx = 1:length(permData.(stream{:}))
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