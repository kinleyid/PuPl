function [Struct1EventBins,Struct2EventBins] = GetEventCorrespondence(Struct1,Struct2,ShowOccurenceCounts)

[Struct1EventTypes,~,ic1] = unique({Struct1.event.type});
[Struct2EventTypes,~,ic2] = unique({Struct2.event.type});

% For show
if strcmp(ShowOccurenceCounts,'ShowOccurenceCounts')
    nStruct1Occurences = accumarray(ic1,1);
    nStruct2Occurences = accumarray(ic2,1);
    Singular = '%s (%d occurence)';
    Plural = '%s (%d occurences)';
    Struct1OptionsForSyncing = cell(length(Struct1EventTypes),1);
    Struct2OptionsForSyncing = cell(length(Struct2EventTypes),1);
    for i = 1:length(Struct1OptionsForSyncing)
        if nStruct1Occurences(i) == 1
            Struct1OptionsForSyncing(i) = {sprintf(Singular,Struct1EventTypes{i},nStruct1Occurences(i))};
        else
            Struct1OptionsForSyncing(i) = {sprintf(Plural,Struct1EventTypes{i},nStruct1Occurences(i))};
        end
    end

    for i = 1:length(Struct2OptionsForSyncing)
        if nStruct2Occurences(i) == 1
            Struct2OptionsForSyncing(i) = {sprintf(Singular,Struct2EventTypes{i},nStruct2Occurences(i))};
        else
            Struct2OptionsForSyncing(i) = {sprintf(Plural,Struct2EventTypes{i},nStruct2Occurences(i))};
        end
    end
else
    Struct1OptionsForSyncing = cellstr(Struct1EventTypes);
    Struct2OptionsForSyncing = cellstr(Struct2EventTypes);
end

nCorrespondences = 1;
Struct1EventBins = [];
Struct2EventBins = [];
while true
    Idx = listdlg('PromptString','Create a pool of events from the first struct',...
        'ListSize',[500,300],...
        'ListString',Struct1OptionsForSyncing);
    Struct1EventBins(nCorrespondences).BinMembers = Struct1EventTypes(Idx);
    
    EventList1 = Struct1EventBins(nCorrespondences).BinMembers{1};
    for i = 2:length(Struct1EventBins(nCorrespondences).BinMembers)
        EventList1 = [EventList1 ', ' Struct1EventBins(nCorrespondences).BinMembers{i}];
    end
    Idx = listdlg('PromptString',sprintf('%s correspond(s) to which event(s) in the other struct?',EventList1),...
        'ListSize',[500,300],...
        'ListString',Struct2OptionsForSyncing);
    Struct2EventBins(nCorrespondences).BinMembers = Struct2EventTypes(Idx);
    
    EventList2 = Struct2EventBins(nCorrespondences).BinMembers{1};
    for i = 2:length(Struct2EventBins(nCorrespondences).BinMembers)
        EventList2 = [EventList2 ', ' Struct2EventBins(nCorrespondences).BinMembers{i}];
    end
    Str = sprintf('%s corresponds to %s\n',EventList1,EventList2);
    Txt(nCorrespondences) = {Str};
    fprintf(Str)
    Answer = questdlg(Txt,'Is this ok?',...
        'Accept','Reject','Add more correspondences','Add more correspondences');
    if strcmp(Answer,'Accept')
        fprintf('%s corresponds to %s\n',EventList1,EventList2)
        fprintf('User accepted correspondence\n\n');
        return
    elseif strcmp(Answer,'Reject')
        fprintf('Never mind, user rejected correspondence\nStarting over...\n\n');
        % Reset
        nCorrespondences = 1;
        Struct1EventBins = [];
        Struct2EventBins = [];
        Txt = {};
    end
    fprintf('User selected to add more correspondences\n\n');
    nCorrespondences = nCorrespondences + 1;
    % Goes back to beginning of while loop if 'Add more correspondences'
    % selected.
end