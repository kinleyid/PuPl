function BinDescriptions = GetBinDescriptions(EYE)

EpochTypes = {'Using single events' 'Using pairs of events'};

Bins = [];

EpochOptions = {};
for Epoch = EYE.epochs
    if strcmp(Epoch.type,EpochTypes{1})
        EpochOptions(numel(EpochOptions)+1) = {sprintf('Defined using instance %d of [%s]',Epoch.info.instanceN,Epoch.info.event{1})};
    elseif strcmp(Epoch.type,EpochTypes{2})
        EpochOptions(numel(EpochOptions)+1) = {sprintf('Defined using instance %d of [%s] and instance %d of [%s]',Epoch.info.instanceN(1),Epoch.info.event{1},Epoch.info.instanceN(2),Epoch.info.event{2})};
    end
end
Question = 'The eye data does not have rejection info. You should really do epoch rejection before binning';
if ~isfield(EYE,'reject')
    Answer = questdlg(Question,Question,'Ok','Not ok (abort)','Not ok (abort)');
    if strcmp(Answer,'Not ok (abort)') || isempty(Answer)
        exit
    else
        EYE.reject = false(size(EYE.epochs));
    end
end
if isempty(EYE.reject)
    Answer = questdlg(Question,Question,'Ok','Not ok (abort)','Not ok (abort)');
    if strcmp(Answer,'Not ok (abort)') || isempty(Answer)
        exit
    else
        EYE.reject = false(size(EYE.epochs));
    end
end

UsableEpochOptions = EpochOptions;

while true
    Question = 'Add a bin?';
    Answer = questdlg(Question,Question,'Yes','No','Yes');
    if strcmp(Answer,'Yes')
        Question = 'Name of bin?';
        Name = inputdlg(Question,Question,1,{sprintf('Bin %d',numel(Bins)+1)});
        if isempty(Name)
            continue
        end
        Name = Name{:};
        Bins(numel(Bins)+1).name = Name;
        Question = sprintf('Which epochs should bin [%s] include?',Name);
        EpochIdxs = listdlg('PromptString',Question,...
                            'ListString',UsableEpochOptions,...
                            'ListSize',[800 800]);
        EpochIdxs = ismember(EpochOptions,UsableEpochOptions(EpochIdxs));
        Bins(end).epochs = CopyEventsAndInstanceNs(EYE.epochs(EpochIdxs));
    else
        break
    end

end

BinDescriptions = Bins;

end

function EpochInfo = CopyEventsAndInstanceNs(Epochs)

EpochInfo = [];
for Epoch = Epochs
    EpochInfo(numel(EpochInfo)+1).type = Epoch.type;
    EpochInfo(end).info.event = Epoch.info.event;
    EpochInfo(end).info.instanceN = Epoch.info.instanceN;
end
    
end