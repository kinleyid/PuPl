
function tempData = applyeyefilter(EYE, filterType, smoothN)

%  Inputs
% EYE--single struct, not array
% filterType
% smoothN

if strcmpi(filterType, 'Median')
    filtfunc = @(x) median(x, 'omitnan');
elseif strcmpi(filterType, 'Mean')
    filtfunc = @(x) median(x, 'omitnan');
elseif strcmpi(filterType, 'Gaussian kernel')
    filtfunc = @gaussiankernel;
end

[permData, tempData] = deal(EYE.data);

for stream = reshape(fieldnames(tempData), 1, [])
    for latIdx = 1:length(permData.left)
        if ~isnan(tempData.(stream{:})(latIdx))
            sLat = max(latIdx-smoothN,1);
            eLat = min(latIdx+smoothN,length(tempData.(stream{:})));
            tempData.(stream{:})(latIdx) = filtfunc(permData.(stream{:})(sLat:eLat));
        end
    end
end