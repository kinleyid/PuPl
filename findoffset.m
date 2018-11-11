function offsetParams = findoffset(Struct1,Struct2,Struct1EventBins,Struct2EventBins)

% Takes 2 structs with struct arrays "event" with fields "type" (string)
% and "time" (in ms), returns Params, the lowest square error solution to
% [Struct1.event.time] = Params(1)*[Struct2.event.time] + Params(2)
% for the correspondence dictated by Struct1EventTypes and
% Struct2EventTypes, where both are themselves struct arrays with field
% "BinMembers" (cell array of strings).

% Should add an option for naming the structs for plotting and printing
% purposes...

while true

    fprintf('Finding offset between timelines...\n')

    nCorrespondences = length(Struct1EventBins);%=length(Struct2EventTypes),equivalently
    Struct1TimesCell = cell(nCorrespondences,1);
    Struct2TimesCell = cell(nCorrespondences,1);
    for i = 1:nCorrespondences
        % Both column vectors
        TempTimes = [Struct1.event(ismember({Struct1.event.type},Struct1EventBins(i).BinMembers)).time];
        Struct1TimesCell(i) = {TempTimes(:)};
        TempTimes = [Struct2.event(ismember({Struct2.event.type},Struct2EventBins(i).BinMembers)).time];
        Struct2TimesCell(i) = {TempTimes(:)};
    end

    AllPossibleOffsets = arrayfun(@(i) Struct1TimesCell{i} - Struct2TimesCell{i}',1:nCorrespondences,'un',0);
    AllPossibleOffsets = arrayfun(@(x) AllPossibleOffsets{x}(:),1:nCorrespondences,'un',0);
    AllPossibleOffsets = cell2mat(AllPossibleOffsets')';

    LowestMSE = inf;
    BestParams = [];
    for CandidateOffset = AllPossibleOffsets
        Struct1TimesVector = [];
        Struct2TimesVector = [];
        for CorrespondenceIdx = 1:nCorrespondences
            % Column
            CurrStruct1Times = Struct1TimesCell{CorrespondenceIdx};
            % Row
            CurrStruct2Times = Struct2TimesCell{CorrespondenceIdx};
            Differences = CurrStruct1Times - CurrStruct2Times';
            Offsets = abs(Differences - CandidateOffset);
            Matches = Offsets < 50; % Tolerance of 50 ms, can be changed
            % Correspondence found for at least 50% of the bin with fewer
            % events
            if nnz(Matches) < 0.5*min([length(CurrStruct1Times) length(CurrStruct2Times)])
                continue
            end
            Struct1TimesVector = cat(1,Struct1TimesVector,CurrStruct1Times(any(Matches,2)));
            Struct2TimesVector = cat(1,Struct2TimesVector,CurrStruct2Times(any(Matches,1)));
        end
        offsetParams = [Struct2TimesVector ones(size(Struct1TimesVector))]\Struct1TimesVector;
        Errs = Struct1TimesVector - [Struct2TimesVector ones(size(Struct1TimesVector))]*offsetParams;
        MSE = mean(Errs.^2);
        if MSE < LowestMSE
            LowestErr = Errs;
            LowestMSE = MSE;
            BestParams = offsetParams;
            Struct1TimesWithMatches = Struct1TimesVector;
        end
    end
    if isempty(BestParams)
        Accepted = questdlg('No offset could be found',...
            'No offset could be found', ...
            'Quit','Try aligning using different events','Try aligning using differenct events');
        if strcmp(Accepted,'Quit')
            return
        else
            [Struct1EventBins,Struct2EventBins] = GetEventCorrespondence(Struct1,Struct2,'ShowOccurenceCounts');
            continue
        end
    else
        offsetParams = BestParams;
    end
    
    % Print results
    % Struct 2's estimated drift relative to struct 1
    TotalTime = (max(Struct2TimesVector)-min(Struct2TimesVector))/1000;
    Drift = offsetParams(1)*TotalTime - TotalTime;
    fprintf('Estimated relative drift: %.3f ms over %.3f seconds.\n',Drift,TotalTime);
    fprintf('Estimated offset: %.3f seconds.\n',offsetParams(2)/offsetParams(1)/1000);
    fprintf('The mean square error is %.2f ms.\n',sqrt(LowestMSE));

    % Plot results
    F1 = figure('units','normalized','outerposition',[0 0 1 1]); hold on
    for i = 1:nCorrespondences
        Times = [Struct1TimesCell{i}(:); [Struct2TimesCell{i}(:) ones(size(Struct2TimesCell{i}(:)))]*offsetParams];
        YCoords = [zeros(size(Struct1TimesCell{i}(:))); ones(size(Struct2TimesCell{i}(:)))];
        scatter(Times,YCoords,10,rand(1,3),'filled')
    end
    for i = 1:length(Struct1TimesWithMatches)
        plot([Struct1TimesWithMatches(i) Struct1TimesWithMatches(i)],[0 1],'k','HandleVisibility','off');
    end

    LegendEntries = cell(1,nCorrespondences);
    for i = 1:nCorrespondences
        LegendEntries(i) = {Struct1EventBins(i).BinMembers{1}};
        for j = 2:length(Struct1EventBins(i))
            LegendEntries(i) = {[LegendEntries{i} ', ' Struct1EventBins(i).BinMembers{j}]};
        end
        LegendEntries(i) = {[LegendEntries{i} '/' Struct2EventBins(i).BinMembers{1}]};
        for j = 2:length(Struct2EventBins(i))
            LegendEntries(i) = [LegendEntries{i} ', ' Struct2EventBins(i).BinMembers{j}];
        end
    end
    legend(LegendEntries);

    ylim([-1 2]);
    yticks([0 1])
    yticklabels({'Struct 1 events' 'Struct 2 events'});
    xlabel('Time (ms)');
    title(sprintf('Alignment between timelines (mean square error: %.2f ms)',sqrt(LowestMSE)))
    F2 = figure; hold on
    histogram(LowestErr)
    title('Histogram of alignment errors');
    xlabel('Error (ms)');
    Accepted = questdlg('Is this alignment acceptable?', ...
        'Accept this alignment?', ...
        'Yes','No (try aligning using differenct events)','Yes');
    close(F1);
    close(F2);
    if strcmp(Accepted,'Yes')
        return
    else
        [Struct1EventBins,Struct2EventBins] = UI_geteventcorrespondence(Struct1,Struct2,'ShowOccurenceCounts');
    end
end