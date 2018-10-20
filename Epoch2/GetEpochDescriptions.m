function EpochDescriptions = GetEpochDescriptions(EYE)

EpochDescriptions = [];

EpochTypes = {'Using single events' 'Using pairs of events'};

LimPrompts = {'Start of epoch (s relative to %s)'
              'End of epoch (s relative to %s)'};

while true
    fprintf('%d epochs currently defined\n',numel(EpochDescriptions))
    Question = 'Add epochs?';
    Answer = questdlg(Question,Question,'Yes','No','Yes');
    if strcmp(Answer,'No') || isempty(Answer)
        fprintf('Created %d epochs\n\n',numel(EpochDescriptions))
        return
    else
        Question = 'Epochs defined:';
        Answer = questdlg(Question,Question,EpochTypes{1},EpochTypes{2},EpochTypes{1});
        if strcmp(Answer,EpochTypes{1}) % Using 1 event
            EventIdxs = listdlg('PromptString','Select the single events','ListString',{EYE.event.type});
            if numel(EventIdxs) == 0 % User cancels or selects nothing
                continue
            elseif numel(EventIdxs) == 1 % User only selected one event
                if numel(find(strcmp({EYE.event.type},EYE.event(EventIdxs).type))) > 1
                    Question = sprintf('Epoch relative to each instance of ''%s''?',EYE.event(EventIdxs).type);
                    Answer = questdlg(Question,Question,'Yes','No','Cancel','Yes');
                    if strcmp(Answer,'Yes')
                        EventIdxs = find(strcmp({EYE.event.type},EYE.event(EventIdxs).type));
                    elseif strcmp(Answer,'No')
                        % Do nothing
                    else
                        continue
                    end
                end
            else % Offer to find the other instances of the selected events
                Question = 'Epoch relative to each instance of the selected events?';
                Answer = questdlg(Question,Question,'Yes','No','Cancel','Yes');
                if strcmp(Answer,'Yes')
                    EventIdxs = find(ismember({EYE.event.type},{EYE.event(EventIdxs).type}));
                elseif strcmp(Answer,'No')
                    % Do nothing
                else
                    continue
                end
            end
            if numel(EventIdxs) > 1
                Question = 'Use the same relative time limits for all epochs?';
                Answer = questdlg(Question,Question,'Yes','No','Cancel','Yes');
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
                EpochDescriptions(length(EpochDescriptions)+1).type = EpochTypes{1};
                EpochDescriptions(end).info = [];
                EpochDescriptions(end).info.event = {EYE.event(EventIdx).type};
                EpochDescriptions(end).info.instanceN = sum(strcmp({EYE.event(1:EventIdx).type},EYE.event(EventIdx).type));
                EpochDescriptions(end).info.lims = Lims;
            end
        elseif strcmp(Answer,EpochTypes{2}) % Using 2 events
            EventIdxs = listdlg('PromptString','Select the pairs of events','ListString',{EYE.event.type});
            if numel(EventIdxs) == 0 % User canceled
                continue
            elseif numel(EventIdxs) == 1 % Need pairs
                uiwait(msgbox('You''re epoching _between_ events, so you need to select more than 1'));
                continue
            elseif numel(EventIdxs) == 2 % User selected 1 pair--option to find each instance of similar pairs
                Txt = sprintf('Create an epoch between each instance of ''%s'' followed by an instance of ''%s?''',EYE.event(EventIdxs(1)).type,EYE.event(EventIdxs(2)).type);
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
                Question = 'Use the same time limits for each epoch?';
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
                EpochDescriptions(length(EpochDescriptions)+1).type = EpochTypes{2};
                EpochDescriptions(end).info = [];
                EpochDescriptions(end).info.event = {EYE.event(EventIdx{:}).type};
                EpochDescriptions(end).info.instanceN = [sum(strcmp({EYE.event(1:EventIdx{:}(1)).type},EYE.event(EventIdx{:}(1)).type))
                                                         sum(strcmp({EYE.event(1:EventIdx{:}(2)).type},EYE.event(EventIdx{:}(2)).type))];
                EpochDescriptions(end).info.lims = Lims;
            end
        end
    end
end