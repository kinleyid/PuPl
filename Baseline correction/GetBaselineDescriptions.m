function BaselineDescriptions = GetBaselineDescriptions(EYE)

BaselineDescriptions = [];

BaselineTypes = {'Using single events' 'Using pairs of events' 'Using epochs'};
EpochTypes = {'Using single events' 'Using pairs of events'};

LimPrompts = {'Start of baseline period (s relative to %s)'
              'End of baseline period (s relative to %s)'};
EpochOptions = {};
for Epoch = EYE.epochs
    if strcmp(Epoch.type,EpochTypes{1})
        EpochOptions(numel(EpochOptions)+1) = {sprintf('Defined using instance %d of [%s]',Epoch.info.instanceN,Epoch.info.event{1})};
    elseif strcmp(Epoch.type,EpochTypes{2})
        EpochOptions(numel(EpochOptions)+1) = {sprintf('Defined using instance %d of [%s] and instance %d of [%s]',Epoch.info.instanceN(1),Epoch.info.event{1},Epoch.info.instanceN(2),Epoch.info.event{2})};
    end
end
UsableEpochOptionsIdx = 1:numel(EpochOptions);

CorrectionTypes = {'Compute percent dilation from baseline average' 'Subtract baseline average' 'No baseline correction'};
Question = 'Use the same type of baseline correction for each baseline?';
Answer = questdlg(Question,Question,'Yes','No','Yes');
if strcmp(Answer,'Yes')
    Question = 'Type of baseline correction?';
    Correction = questdlg(Question,Question,CorrectionTypes{1},CorrectionTypes{2},CorrectionTypes{3},CorrectionTypes{1});
	SameCorrection = true;
else
    SameCorrection = false;
    Correction = CorrectionTypes{1};
end

while true
    if isempty(UsableEpochOptionsIdx)
        uiwait(msgbox('No more epochs to baseline-correct'));
        return
    end
    Question = 'Add baselines?';
    Answer = questdlg(Question,Question,'Yes','No','Yes');
    if strcmp(Answer,'No') || isempty(Answer)
        return
    else
        Question = 'Baselines defined:';
        Answer = questdlg(Question,Question,BaselineTypes{1},BaselineTypes{2},BaselineTypes{3},BaselineTypes{3});
        if isempty(Answer)
            continue
        elseif strcmp(Answer,BaselineTypes{3}) % Using epochs
            CurrEpochOptions = EpochOptions(UsableEpochOptionsIdx);
            RelativeEpochIdxs = listdlg('PromptString','Select the epochs to correct',...
                                        'ListString',CurrEpochOptions,...
                                        'ListSize',[800 800]);
            AbsoluteEpochIdxs = ismember(EpochOptions,CurrEpochOptions(RelativeEpochIdxs));
            UsableEpochOptionsIdx(RelativeEpochIdxs) = [];
            if isempty(AbsoluteEpochIdxs)
                continue
            elseif numel(AbsoluteEpochIdxs) > 1
                Question = 'Use the same relative time limits for all selected epochs?';
                Answer = questdlg(Question,Question,'Yes','No','Cancel','No');
                if strcmp(Answer,'Yes')
                    Question = 'Use the start of the epoch, the end of the epoch, or both as reference points?';
                    Answer = questdlg(Question,Question,'Start','End','Both','Start');
                    RefPoints = Answer;
                    if strcmp(Answer,'Start')
                        Prompts = {sprintf(LimPrompts{1},'start of epoch') sprintf(LimPrompts{2},'start of epoch')};
                    elseif strcmp(Answer,'End')
                        Prompts = {sprintf(LimPrompts{1},'end of epoch') sprintf(LimPrompts{2},'end of epoch')};
                    elseif strcmp(Answer,'Both')
                        Prompts = {sprintf(LimPrompts{1},'start of epoch') sprintf(LimPrompts{2},'end of epoch')};
                    end
                    Answer = inputdlg(Prompts);
                    if isempty(Answer)
                        continue
                    end
                    Lims = [str2double(Answer{1}) str2double(Answer{2})];
                    if ~SameCorrection
                        Question = 'Type of baseline correction?';
                        Correction = questdlg(Question,Question,CorrectionTypes{1},CorrectionTypes{2},CorrectionTypes{3},Correction);
                    end
                    BaselineDescriptions(numel(BaselineDescriptions)+1).type = BaselineTypes{3};
                    BaselineDescriptions(end).correction = Correction;
                    BaselineDescriptions(end).epochs = CopyEventsAndInstanceNs(EYE.epochs(AbsoluteEpochIdxs));
                    BaselineDescriptions(end).info = [];
                    BaselineDescriptions(end).info.lims = Lims;
                    BaselineDescriptions(end).info.refpoints = RefPoints;
                    continue
                elseif strcmp(Answer,'Cancel') || isempty(Anser)
                    continue
                end
            end
            % This point is only reached if numel(EpochIdxs == 1) or if
            % different time lims will be used for each epoch
            RefPoints = 'Start';
            for EpochIdx = AbsoluteEpochIdxs
                Question = 'Use the start of the epoch, the end of the epoch, or both as reference points?';
                Answer = questdlg(Question,Question,'Start','End','Both',RefPoints);
                RefPoints = Answer;
                if strcmp(Answer,'Start')
                    Prompts = {sprintf(LimPrompts{1},'start of epoch') sprintf(LimPrompts{2},'start of epoch')};
                elseif strcmp(Answer,'End')
                    Prompts = {sprintf(LimPrompts{1},'end of epoch') sprintf(LimPrompts{2},'end of epoch')};
                elseif strcmp(Answer,'Both')
                    Prompts = {sprintf(LimPrompts{1},'start of epoch') sprintf(LimPrompts{2},'end of epoch')};
                end
                Answer = inputdlg(Prompts);
                if isempty(Answer)
                    continue
                end
                Lims = [str2double(Answer{1}) str2double(Answer{2})];
                if ~SameCorrection
                    Question = 'Type of baseline correction?';
                    Correction = questdlg(Question,Question,CorrectionTypes{1},CorrectionTypes{2},CorrectionTypes{3},Correction);
                end
                BaselineDescriptions(numel(BaselineDescriptions)+1).type = BaselineTypes{3};
                BaselineDescriptions(end).correction = Correction;
                BaselineDescriptions(end).epochs = CopyEventsAndInstanceNs(EYE.epochs(EpochIdx));
                BaselineDescriptions(end).info = [];
                BaselineDescriptions(end).info.lims = Lims;
                BaselineDescriptions(end).info.refpoints = RefPoints;
            end
        elseif strcmp(Answer,BaselineTypes{1}) % Using 1 event
            EventIdxs = listdlg('PromptString','Select the single events','ListString',{EYE.event.type});
            if numel(EventIdxs) == 0 % User cancels or selects nothing
                continue
            elseif numel(EventIdxs) == 1 % User only selected one event
                if numel(find(strcmp({EYE.event.type},EYE.event(EventIdxs).type))) > 1
                    Question = sprintf('Create a baseline relative to each instance of ''%s''?',EYE.event(EventIdxs).type);
                    Answer = questdlg(Question,Question,'Yes','No','Cancel','Yes');
                    if strcmp(Answer,'Yes')
                        EventIdxs = find(strcmp({EYE.event.type},EYE.event(EventIdxs).type));
                    elseif strcmp(Answer,'No')
                        % Do nothing
                    else
                        continue
                    end
                end
            end
            if numel(EventIdxs) > 1
                Question = 'Use the same relative time limits for all selected events?';
                Answer = questdlg(Question,Question,'Yes','No','Cancel','No');
                if strcmp(Answer,'Yes')
                    Prompts = {sprintf(LimPrompts{1},'event') sprintf(LimPrompts{2},'event')};
                    Answer = inputdlg(Prompts);
                    if isempty(Answer)
                        continue
                    end
                    Lims = [str2double(Answer{1}) str2double(Answer{2})];
                    SameForEach = true;
                elseif strcmp(Answer,'No')
                    SameForEach = false;
                else
                    continue
                end
            else
                SameForEach = false;
            end
            for EventIdx = EventIdxs
                if ~SameForEach
                    String = sprintf('instance %d of ''%s''',sum(strcmp({EYE.event(1:EventIdx).type},EYE.event(EventIdx).type)),EYE.event(EventIdx).type);
                    Prompts = {sprintf(LimPrompts{1},String) sprintf(LimPrompts{2},String)};
                    Answer = inputdlg(Prompts);
                    if isempty(Answer)
                        continue
                    end
                    Lims = [str2double(Answer{1}) str2double(Answer{2})];
                end
                if ~SameCorrection
                    Question = 'Type of baseline correction?';
                    Correction = questdlg(Question,Question,CorrectionTypes{1},CorrectionTypes{2},CorrectionTypes{3},Correction);
                end
                BaselineDescriptions(length(BaselineDescriptions)+1).type = BaselineTypes{1};
                BaselineDescriptions(end).correction = Correction;
                BaselineDescriptions(end).info = [];
                BaselineDescriptions(end).info.event = {EYE.event(EventIdx).type};
                BaselineDescriptions(end).info.instanceN = sum(strcmp({EYE.event(1:EventIdx).type},EYE.event(EventIdx).type));
                BaselineDescriptions(end).info.lims = Lims;
                CurrEpochOptions = EpochOptions(UsableEpochOptionsIdx);
                RelativeEpochIdxs = listdlg('PromptString','Select the epochs to correct using this baseline',...
                                            'ListString',CurrEpochOptions,...
                                            'ListSize',[800 800]);
                AbsoluteEpochIdxs = ismember(EpochOptions,CurrEpochOptions(RelativeEpochIdxs));
                UsableEpochOptionsIdx(RelativeEpochIdxs) = [];
                BaselineDescriptions(end).epochs = CopyEventsAndInstanceNs(EYE.epochs(AbsoluteEpochIdxs));
                if isempty(UsableEpochOptionsIdx)
                    uiwait(msgbox('No more epochs to baseline-correct'));
                    return
                end
            end
        elseif strcmp(Answer,BaselineTypes{2}) % Using 2 events
            EventIdxs = listdlg('PromptString','Select the pairs of events','ListString',{EYE.event.type});
            if numel(EventIdxs) == 0 % User canceled
                continue
            elseif numel(EventIdxs) == 1 % Need pairs
                uiwait(msgbox('You''re epoching _between_ events, so you need to select more than 1'));
                continue
            elseif numel(EventIdxs) == 2 % User selected 1 pair--option to find each instance of similar pairs
                Txt = sprintf('Create a baseline between each instance of ''%s'' followed by an instance of ''%s?''',EYE.event(EventIdxs(1)).type,EYE.event(EventIdxs(2)).type);
                Answer = questdlg(Txt,Txt,'Yes','No','Yes');
                if strcmp(Answer,'Yes')
                    NewEventIdxs = cell(0);
                    FirstEventIdxs = find(strcmp({EYE.event.type},EYE.event(EventIdxs(1)).type));
                    SecondEventIdxs = find(strcmp({EYE.event.type},EYE.event(EventIdxs(2)).type));
                    for i = 1:length(FirstEventIdxs)
                        for j = 1:length(SecondEventIdxs)
                            if SecondEventIdxs(j) > FirstEventIdxs(i)
                                if i < length(FirstEventIdxs)
                                    if SecondEventIdxs(j) > FirstEventIdxs(i+1)
                                        continue
                                    end
                                end
                                NewEventIdxs(numel(NewEventIdxs)+1) = {[FirstEventIdxs(i) SecondEventIdxs(j)]};
                            end
                        end
                    end
                end
            else % User selected multiple pairs
                Question = 'Treat the end of one epoch as the start of the next?';
                Answer = questdlg(Question,Question,'Yes','No','Cancel','Yes');
                if strcmp(Answer,'Yes')
                    NewEventIdxs = cell(0);
                    for i = 1:numel(EventIdxs)-1
                        NewEventIdxs(numel(NewEventIdxs)+1) = {[EventIdxs(i) EventIdxs(i+1)]};
                    end
                elseif strcmp(Answer,'No')
                    if mod(numel(EventIdxs),2) ~= 0
                        uiwait(msgbox('In that case, select an even number of events'));
                        continue
                    end
                    NewEventIdxs = cell(0);
                    for i = 1:2:numel(EventIdxs)
                        NewEventIdxs(numel(NewEventIdxs)+1) = {[EventIdxs(i) EventIdxs(i+1)]};
                    end
                else
                    continue
                end
            end
            EventIdxs = NewEventIdxs;
            if numel(EventIdxs) > 2
                Question = 'Use the same time limits for each baseline?';
                Answer = questdlg(Question,Question,'Yes','No','Cancel','No');
                if strcmp(Answer,'Yes')
                    Prompts = {sprintf(LimPrompts{1},'first event') sprintf(LimPrompts{2},'second event')};
                    Answer = inputdlg(Prompts);
                    if isempty(Answer)
                        continue
                    end
                    Lims = [str2double(Answer{1}) str2double(Answer{2})];
                    SameForEach = true;
                elseif strcmp(Answer,'No')
                    SameForEach = false;
                else
                    continue
                end
            end
            for EventIdx = EventIdxs
                if ~SameForEach
                    String1 = sprintf('instance %d of %s',sum(strcmp({EYE.event(1:EventIdx{:}(1)).type},EYE.event(EventIdx{:}(1)).type)),EYE.event(EventIdx{:}(1)).type);
                    String2 = sprintf('instance %d of %s',sum(strcmp({EYE.event(1:EventIdx{:}(2)).type},EYE.event(EventIdx{:}(2)).type)),EYE.event(EventIdx{:}(2)).type);
                    Prompts = {sprintf(LimPrompts{1},String1) sprintf(LimPrompts{2},String2)};
                    Answer = inputdlg(Prompts);
                    if isempty(Answer)
                        continue
                    end
                    Lims = [str2double(Answer{1}) str2double(Answer{2})];
                end
                if ~SameCorrection
                    Question = 'Type of baseline correction?';
                    Correction = questdlg(Question,Question,CorrectionTypes{1},CorrectionTypes{2},CorrectionTypes{3},Correction);
                end
                BaselineDescriptions(length(BaselineDescriptions)+1).type = BaselineTypes{2};
                BaselineDescriptions(end).correction = Correction;
                BaselineDescriptions(end).info = [];
                BaselineDescriptions(end).info.event = {EYE.event(EventIdx{:}).type};
                BaselineDescriptions(end).info.instanceN = [sum(strcmp({EYE.event(1:EventIdx{:}(1)).type},EYE.event(EventIdx{:}(1)).type))
                                                         sum(strcmp({EYE.event(1:EventIdx{:}(2)).type},EYE.event(EventIdx{:}(2)).type))];
                BaselineDescriptions(end).info.lims = Lims;
                CurrEpochOptions = EpochOptions(UsableEpochOptionsIdx);
                PromptString = sprintf('Select epochs to correct using baseline defined by instance %d of [%s] and instance %d of [%s]',BaselineDescriptions(end).info.instanceN(1),BaselineDescriptions(end).info.event{1},BaselineDescriptions(end).info.instanceN(2),BaselineDescriptions(end).info.event{2});
                RelativeEpochIdxs = listdlg('PromptString',PromptString,...
                                            'ListString',CurrEpochOptions,...
                                            'ListSize',[800 800]);
                AbsoluteEpochIdxs = ismember(EpochOptions,CurrEpochOptions(RelativeEpochIdxs));
                UsableEpochOptionsIdx(RelativeEpochIdxs) = [];
                BaselineDescriptions(end).epochs = CopyEventsAndInstanceNs(EYE.epochs(AbsoluteEpochIdxs));
                if isempty(UsableEpochOptionsIdx)
                    uiwait(msgbox('No more epochs to baseline-correct'));
                    return
                end
            end
        end
    end
end

end

function EpochInfo = CopyEventsAndInstanceNs(Epochs)

EpochInfo = [];
for Epoch = Epochs
    EpochInfo(numel(EpochInfo)+1).type = Epoch.type;
    EpochInfo(end).info.event = Epoch.info.event;
    EpochInfo(end).info.instanceN = Epoch.info.instanceN;
end
    
end