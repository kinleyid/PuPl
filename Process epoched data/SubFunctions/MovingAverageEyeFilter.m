function EYEout = MovingAverageEyeFilter(EYE,SmoothN,Type)

% Takes the median of smoothN points on either side of points. Skips over
% NaNs, excludes NaNs from the average.

fprintf('Applying a %s filter with parameter %d...',Type,SmoothN);

for EpochIdx = 1:length(EYE.epochs)
    % Show a different unrejected event each time
    PermLData = EYE.epochdata(EpochIdx).pupilL(:);
    TempLData = PermLData(:);
    PermRData = EYE.epochdata(EpochIdx).pupilR(:);
    TempRData = PermRData(:);

    for i = 1:length(TempLData)
        sLat = max(i-SmoothN,1);
        eLat = min(i+SmoothN,length(TempLData));
        if ~isnan(PermLData(i))
            if strcmp(Type,'Median')
                TempLData(i) = median(PermLData(sLat:eLat),'omitnan');
            elseif strcmp(Type,'Mean')
                TempLData(i) = mean(PermLData(sLat:eLat),'omitnan');
            elseif strcmp(Type,'Gaussian kernel')
                if SmoothN == 0
                    TempLData(i) = PermLData(i);
                else
                    Gau = exp(-((((sLat:eLat)-i)/(SmoothN/3)).^2));
                    TempLData(i) = sum(Gau(:).*PermLData(sLat:eLat),'omitnan');
                    TempLData(i) = TempLData(i)/sum(Gau(~isnan(PermLData(sLat:eLat))));
                end
            end
        else
            TempLData(i) = NaN;
        end
        if ~isnan(PermRData(i))
            if strcmp(Type,'Median')
                TempRData(i) = median(PermRData(sLat:eLat),'omitnan');
            elseif strcmp(Type,'Mean')
                TempRData(i) = mean(PermRData(sLat:eLat),'omitnan');
            elseif strcmp(Type,'Gaussian kernel')
                if SmoothN == 0
                    TempRData(i) = PermRData(i);
                else
                    Gau = exp(-((((sLat:eLat)-i)/(SmoothN/3)).^2));
                    TempRData(i) = sum(Gau(:).*PermRData(sLat:eLat),'omitnan');
                    TempRData(i) = TempRData(i)/sum(Gau(~isnan(PermRData(sLat:eLat))));
                end
            end
        else
            TempRData(i) = NaN;
        end
    end
    EYE.epochdata(EpochIdx).pupilL = TempLData;
    EYE.epochdata(EpochIdx).pupilR = TempRData;
end

EYEout = EYE;
fprintf('done.\n');