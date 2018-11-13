function bestOffsetParams = findtimelineoffset(EYE, eventLog, eyeEventSets, eventLogEventSets, varargin)

%   Inputs
% EYE--single struct
% eventLog--single struct

% Takes 2 structs with struct arrays "event" with fields "type" (string)
% and "time" (in ms), returns Params, the lowest square error solution to
% [Struct1.event.time] = Params(1)*[Struct2.event.time] + Params(2)
% for the correspondence dictated by Struct1EventTypes and
% Struct2EventTypes, where both are themselves struct arrays with field
% "BinMembers" (cell array of strings).

% Should add an option for naming the structs for plotting and printing
% purposes...

if numel(varargin) < 1
    tolerance = 50;
else
    tolerance = varargin{1};
end

if numel(varargin) < 2
    pct = 0.5;
else
    pct = varargin{2};
end

allPossibleOffsets = reshape(mergefields(EYE, 'event', 'time') - mergefields(eventLog, 'event', 'time'), 1, []);

while true
    lowestErr = inf;
    bestParams = [];
    for candidateOffset = allPossibleOffsets
        eyeTimes = [];
        eventLogTimes = [];
        for i = 1:numel(eyeEventSets)
            currEyeTimes = mergefields(EYE.event(ismember({EYE.event.name}, eyeEventSets)), 'time');
            currEventLogTimes = mergefields(eventLog.event(ismember({eventLog.event.name}, eventLogEventSets)), 'time');
            matches = abs(currEyeTimes(:) - currEventLogTimes(:)' - candidateOffset) < tolerance;
            if nnz(matches) < pct*min(size(matches))
                continue
            else
                eyeTimes = cat(1, eyeTimes, reshape(currEyeTimes(any(matches, 2)), [], 1));
                eventLogTimes = cat(1, eventLogTimes, reshape(currEventLogTimes(any(matches, 1)), [], 1));
            end
        end
        currOffsetParams = [eventLogTimes ones(size(eventLogTimes))] \ eyeTimes;
        currErr = sum((eyeTimes - [eventLogTimes ones(size(eventLogTimes))]*currOffsetParams).^2);
        if currErr < lowestErr
            lowestErr = currErr;
            bestOffsetParams = currOffsetParams;
        end
    end
    % Something here about showing the user the offset
    if isempty(bestParams)
        q = 'No offset could be found';
        a = questdlg(q, q, 'Quit', 'Try different events', 'Try different events');
        if strcmp(a, 'Quit')
            return
        elseif strcmp(a, 'Try difference events')
            [eyeEventSets, eventLogEventSets] = UI_geteventcorrespondence(EYE, eventLog);
        end
    else
        return
    end
end

end

%{
while true

    fprintf('Finding offset between timelines...\n')

    nCorrespondences = length(eyeEventSets);%=length(Struct2EventTypes),equivalently
    eyeTimesCell = cell(nCorrespondences,1);
    eventLogTimesCell = cell(nCorrespondences,1);
    for i = 1:nCorrespondences
        % Both column vectors
        tempTimes = [EYE.event(ismember({EYE.event.type},eyeEventSets(i).BinMembers)).time];
        eyeTimesCell(i) = {tempTimes(:)};
        tempTimes = [eventLog.event(ismember({eventLog.event.type},eventLogEventSets(i).BinMembers)).time];
        eventLogTimesCell(i) = {tempTimes(:)};
    end
    
    allPossibleOffsets = arrayfun(@(i) eyeTimesCell{i} - eventLogTimesCell{i}',1:nCorrespondences,'un',0);
    allPossibleOffsets = arrayfun(@(x) allPossibleOffsets{x}(:),1:nCorrespondences,'un',0);
    allPossibleOffsets = cell2mat(allPossibleOffsets')';

    lowestMSE = inf;
    bestParams = [];
    for candidateOffset = allPossibleOffsets
        eyeTimesVector = [];
        eventLogTimesVector = [];
        for correspondenceIdx = 1:nCorrespondences
            % Column
            currEyeTimes = eyeTimesCell{correspondenceIdx};
            % Row
            eventLogTimes = eventLogTimesCell{correspondenceIdx};
            differences = currEyeTimes - eventLogTimes';
            offsets = abs(differences - candidateOffset);
            matches = offsets < 50; % Tolerance of 50 ms, can be changed
            % Correspondence found for at least 50% of the bin with fewer
            % events
            if nnz(matches) < 0.5*min([length(currEyeTimes) length(eventLogTimes)])
                continue
            end
            eyeTimesVector = cat(1,eyeTimesVector,currEyeTimes(any(matches,2)));
            eventLogTimesVector = cat(1,eventLogTimesVector,eventLogTimes(any(matches,1)));
        end
        offsetParams = [eventLogTimesVector ones(size(eyeTimesVector))]\eyeTimesVector;
        errs = eyeTimesVector - [eventLogTimesVector ones(size(eyeTimesVector))]*offsetParams;
        MSE = mean(errs.^2);
        if MSE < lowestMSE
            lowestErr = errs;
            lowestMSE = MSE;
            bestParams = offsetParams;
            eyeTimesWithMatches = eyeTimesVector;
        end
    end
    if isempty(bestParams)
        accepted = questdlg('No offset could be found',...
            'No offset could be found', ...
            'Quit','Try aligning using different events','Try aligning using differenct events');
        if strcmp(accepted,'Quit')
            return
        else
            [eyeEventSets,eventLogEventSets] = UI_geteventcorrespondence(EYE,eventLog,'ShowOccurenceCounts');
            continue
        end
    else
        offsetParams = bestParams;
    end
    
    % Print results
    % Struct 2's estimated drift relative to struct 1
    totalTime = (max(eventLogTimesVector)-min(eventLogTimesVector))/1000;
    drift = offsetParams(1)*totalTime - totalTime;
    fprintf('Estimated relative drift: %.3f ms over %.3f seconds.\n',drift,totalTime);
    fprintf('Estimated offset: %.3f seconds.\n',offsetParams(2)/offsetParams(1)/1000);
    fprintf('The mean square error is %.2f ms.\n',sqrt(lowestMSE));

    % Plot results
    F1 = figure('units','normalized','outerposition',[0 0 1 1]); hold on
    for i = 1:nCorrespondences
        Times = [eyeTimesCell{i}(:); [eventLogTimesCell{i}(:) ones(size(eventLogTimesCell{i}(:)))]*offsetParams];
        YCoords = [zeros(size(eyeTimesCell{i}(:))); ones(size(eventLogTimesCell{i}(:)))];
        scatter(Times,YCoords,10,rand(1,3),'filled')
    end
    for i = 1:length(eyeTimesWithMatches)
        plot([eyeTimesWithMatches(i) eyeTimesWithMatches(i)],[0 1],'k','HandleVisibility','off');
    end
    
    legendEntries = cell(1,nCorrespondences);
    for i = 1:nCorrespondences
        legendEntries(i) = {eyeEventSets(i).BinMembers{1}};
        for j = 2:length(eyeEventSets(i))
            legendEntries(i) = {[legendEntries{i} ', ' eyeEventSets(i).BinMembers{j}]};
        end
        legendEntries(i) = {[legendEntries{i} '/' eventLogEventSets(i).BinMembers{1}]};
        for j = 2:length(eventLogEventSets(i))
            legendEntries(i) = [legendEntries{i} ', ' eventLogEventSets(i).BinMembers{j}];
        end
    end
    legend(legendEntries);

    ylim([-1 2]);
    yticks([0 1])
    yticklabels({'Struct 1 events' 'Struct 2 events'});
    xlabel('Time (ms)');
    title(sprintf('Alignment between timelines (mean square error: %.2f ms)',sqrt(lowestMSE)))
    F2 = figure; hold on
    histogram(lowestErr)
    title('Histogram of alignment errors');
    xlabel('Error (ms)');
    accepted = questdlg('Is this alignment acceptable?', ...
        'Accept this alignment?', ...
        'Yes','No (try aligning using differenct events)','Yes');
    close(F1);
    close(F2);
    if strcmp(accepted,'Yes')
        return
    else
        [eyeEventSets,eventLogEventSets] = UI_geteventcorrespondence(EYE,eventLog,'ShowOccurenceCounts');
    end
end
%}