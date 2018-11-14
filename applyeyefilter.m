
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

[permData, tempData] = deal(EYE.data);

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