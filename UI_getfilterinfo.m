function [filterType, smoothN] = UI_getfilterinfo(EYE)

%   Inputs
% EYE--struct array
%   Outputs

[filterType, smoothN] = filterquery;

figure('units', 'normalized', 'outerposition', [0 0 1 1])

while true
    dataIdx = randi(numel(EYE));
    permData = deal(EYE(dataIdx).data);
    tempData = applyeyefilter(EYE(dataIdx), filterType, smoothN);
    
    nSecondsToPlot = 5; % Number of seconds of data to plot
    start = randi(length(tempData.left) - nSecondsToPlot*EYE(1).srate);
    latencies = start:(start + nSecondsToPlot*EYE.srate);
    
    clf; hold on
    plot(tempData.right(latencies), 'r')
    plot(permData.right(latencies), 'r:')
    plot(tempData.left(latencies), 'b')
    plot(permData.left(latencies), 'b:')
    legend({'Right eye smoothed' 'Right eye original' 'Left eye smoothed' 'Left eye original'})
    title(sprintf('Moving %s of %d points on either side (%d seconds of data)', filterType, smoothN, nSecondsToPlot));
    xlim([1 numel(latencies)]);
    
    Accepted = questdlg('Is this smoothing acceptable?',...
        'Accept this smoothing?',...
        'Yes', 'See a different epoch', 'Try different smoothing', 'See a different epoch');
    if strcmp(Accepted,'Yes')
        close
        return
    elseif strcmp(Accepted,'Try different smoothing')
        [filterType, smoothN] = filterquery(filterType, smoothN);
    end
end

end

function [filterType, smoothN] = filterquery(varargin)

filterOptions = {'Median' 'Mean' 'Gaussian kernel'};

if nargin < 1
    defaultFilterType = 'Median';
else
    defaultFilterType = varargin{1};
end

if nargin < 2
    defaultSmoothN = {'8'};
else
    defaultSmoothN = {num2str(varargin{2})};
end

q = 'Which type of moving average?';
filterType = questdlg(q, q, filterOptions{:}, defaultFilterType);
q = 'Average of how many points on either side?';
smoothN = str2double(inputdlg(q, q, 1, defaultSmoothN));

end