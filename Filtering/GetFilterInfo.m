function [SmoothN,Type] = GetFilterInfo(Path,Filenames,FilterTypes)


Question = 'Which type of moving average?';
Type = questdlg(Question,Question,FilterTypes{1},FilterTypes{2},FilterTypes{3},FilterTypes{1});
Question = 'Average of how many points on either side?';
Answer = inputdlg(Question,Question,1,{'8'});
SmoothN = str2double(Answer);

figure('units','normalized','outerposition',[0 0 1 1]);

while true
    % Show a different unrejected event each time
    MatData = load([Path Filenames{randi(length(Filenames))}]);
    EYE = MatData.EYE;
    
    PermLData = EYE.data.left(:);
    TempLData = PermLData(:);
    PermRData = EYE.data.right(:);
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
    nSeconds = 5; % Number of seconds of data to plot
    Idx = randi(length(EYE.data.left)-nSeconds*EYE.srate);
    Idx = Idx:(Idx+nSeconds*EYE.srate); % Plot 5 random seconds
    clf; hold on
    plot(TempRData(Idx),'r'); plot(PermRData(Idx),'r:')
    plot(TempLData(Idx),'b'); plot(PermLData(Idx),'b:')
    legend({'Right eye smoothed' 'Right eye original' 'Left eye smoothed' 'Left eye original'})
    title(sprintf('Moving %s of %d points on either side (%d seconds of data)',Type,SmoothN,nSeconds));
    Accepted = questdlg('Is this smoothing acceptable?', ...
        'Accept this smoothing?', ...
        'Yes','See a different epoch','Try different smoothing','See a different epoch');
    if strcmp(Accepted,'Yes')
        fprintf('User accepted smoothing parameter %d\n',SmoothN);
       close; break
    elseif strcmp(Accepted,'Try different smoothing')
        Question = 'Which type of moving average?';
        Type = questdlg(Question,Question,FilterTypes{1},FilterTypes{2},FilterTypes{3},FilterTypes{1});
        Question = 'Average of how many points on either side?';
        Answer = inputdlg(Question,Question,1,{'8'});
        SmoothN = str2double(Answer);
        fprintf('User switched smoothing parameter to %d\n',SmoothN);
    end
end
end