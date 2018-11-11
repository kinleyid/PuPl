function [filterType, smoothN] = UI_getfilterinfo(EYE)

%  Inputs
% EYE--struct array
%  Outputs

FilterTypes = {'Median' 'Mean' 'Gaussian kernel'};

Question = 'Which type of moving average?';
filterType = questdlg(Question,Question,FilterTypes{1},FilterTypes{2},FilterTypes{3},FilterTypes{1});
Question = 'Average of how many points on either side?';
Answer = inputdlg(Question,Question,1,{'8'});
smoothN = str2double(Answer);

figure('units','normalized','outerposition',[0 0 1 1]);

while true
    % Show a different 3 seconds of data each time
    dataIdx = randi(numel(EYE));
    permData = deal(EYE(dataIdx).data);
    tempData = applyeyefilter(EYE(dataIdx), filterType, smoothN);
    
    
    nSeconds = 5; % Number of seconds of data to plot
    start = randi(length(tempData.left)-nSeconds*EYE(1).srate);
    latencies = start:(start+nSeconds*EYE.srate); % Plot 5 random seconds
    clf; hold on
    plot(tempData.right(latencies),'r'); plot(permData.right(latencies),'r:')
    plot(tempData.left(latencies),'b'); plot(permData.left(latencies),'b:')
    legend({'Right eye smoothed' 'Right eye original' 'Left eye smoothed' 'Left eye original'})
    title(sprintf('Moving %s of %d points on either side (%d seconds of data)',filterType,smoothN,nSeconds));
    xlim([1 numel(latencies)]);
    
    Accepted = questdlg('Is this smoothing acceptable?', ...
        'Accept this smoothing?', ...
        'Yes','See a different epoch','Try different smoothing','See a different epoch');
    if strcmp(Accepted,'Yes')
        fprintf('User accepted smoothing parameter %d\n',smoothN);
       close; break
    elseif strcmp(Accepted,'Try different smoothing')
        Question = 'Which type of moving average?';
        filterType = questdlg(Question,Question,...
            FilterTypes{1},FilterTypes{2},FilterTypes{3},filterType);
        Question = 'Average of how many points on either side?';
        Answer = inputdlg(Question,Question,1,{num2str(smoothN)});
        smoothN = str2double(Answer);
        fprintf('User switched smoothing parameter to %d\n',smoothN);
    end
end
end