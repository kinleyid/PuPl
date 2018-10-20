function [SmoothN,Type] = GetMovingAverageParam(Path,Filenames)

Type = questdlg('Which type of moving average?', ...
        'Which type of moving average?', ...
        'Median','Mean','Gaussian kernel','Median');
Answer = inputdlg('Average of how many points on either side? (0 for no moving average)',...
                  'Choose smoothing parameter',1,{'8'});
SmoothN = str2double(Answer);
              
figure('units','normalized','outerposition',[0 0 1 1]);
MatData = load([Path Filenames{randi(length(Filenames))}]);
EYE = MatData.EYE;
EYE.reject = false(1,length(EYE.epochs));
UsableEpochsIdx = find(~EYE.reject);
while true
    % Show a different unrejected event each time
    EpochIdx = randperm(length(UsableEpochsIdx));
    EpochIdx = UsableEpochsIdx(EpochIdx(1));
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
    clf; hold on
    plot(TempRData,'r'); plot(PermRData,'r:')
    plot(TempLData,'b'); plot(PermLData,'b:')
    legend({'Right eye smoothed' 'Right eye original' 'Left eye smoothed' 'Left eye original'})
    title(sprintf('Moving %s of %d points on either side',Type,SmoothN));
    Accepted = questdlg('Is this smoothing acceptable?', ...
        'Accept this smoothing?', ...
        'Yes','See a different epoch','Try different smoothing','See a different epoch');
    if strcmp(Accepted,'Yes')
        fprintf('User accepted smoothing parameter %d\n',SmoothN);
       close; break
    elseif strcmp(Accepted,'Try different smoothing')
        Type = questdlg('Which type of moving average?', ...
                        'Which type of moving average?', ...
                        'Median','Mean','Gaussian kernel',Type);
        Answer = inputdlg('Moving average will be average of how many points on either side? (0 for no moving average)',...
                          'Choose smoothing parameter',...
                          1,{num2str(SmoothN)});
        SmoothN = str2double(Answer);
        fprintf('User switched smoothing parameter to %d\n',SmoothN);
    end
end
end