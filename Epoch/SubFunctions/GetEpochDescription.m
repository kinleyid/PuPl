function Epochs = GetEpochDescription(EYE)

% Get descriptions of epochs

Epochs = [];

while true
    Answer = questdlg('Add epochs?','Add epochs?','Yes','No','No');
    if strcmp(Answer,'No')
        break
    else
        Answer = questdlg('Epoch type:','Epoch type:','Length of time relative to events','Between events','Length of time relative to events');
        if strcmp(Answer,'Length of time relative to events')
            Prompts = {'Start of epoch (s) (E.g. -0.2 means 200 ms before event, 0 means onset of event)'
                       'End of epoch (s) (E.g. 1.8 means 1.8 s after event)'};
            EventIdxs = listdlg('PromptString','Select the events','ListString',{EYE.event.type});
            if numel(EventIdxs) == 0
                continue
            elseif numel(EventIdxs) == 1
                Txt = sprintf('Epoch relative to each instance of %s?',EYE.event(EventIdxs).type);
                Answer = questdlg(Txt,Txt,'Yes','No','Yes');
                if strcmp(Answer,'Yes')
                    EventIdxs = find(strcmp({EYE.event.type},EYE.event(EventIdxs).type));
                end
            end
            if numel(EventIdxs) > 1
                Answer = questdlg('Use the same relative time limits for all selected events?','Use the same relative time limits for all selected events?','Yes','No','No');
                if strcmp(Answer,'Yes')
                    Answer = inputdlg(Prompts);
                    Lims = [str2double(Answer{1}) str2double(Answer{2})];
                    SameForEach = true;
                else
                    SameForEach = false;
                end
            end
            for EventIdx = EventIdxs
                if ~SameForEach
                    Answer = inputdlg(Prompts);
                    Lims = [str2double(Answer{1}) str2double(Answer{2})];
                end
                Epochs(length(Epochs)+1).EventType = cellstr(EYE.event(EventIdx).type);
                Epochs(end).InstanceN = sum(strcmp({EYE.event(1:EventIdx).type},EYE.event(EventIdx).type));
                Epochs(end).EpochType = 'Length of time relative to events';
                Epochs(end).Lims = Lims;
            end

        elseif strcmp(Answer,'Between events')
            EventIdxs = listdlg('PromptString','Select the events','ListString',{EYE.event.type});
            if numel(EventIdxs) == 0
                continue
            elseif numel(EventIdxs) == 1
                uiwait(msgbox('You''re epoching _between_ events, so you need to select more than 1'));
                continue
            elseif numel(EventIdxs) == 2
                Txt = sprintf('Create an epoch between each instance of %s followed by an instance of %s?',EYE.event(EventIdxs(1)).type,EYE.event(EventIdxs(2)).type);
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
            else
                NewEventIdxs = cell(0);
                for i = 1:numel(EventIdxs)-1
                    NewEventIdxs(numel(NewEventIdxs)+1) = {[EventIdxs(i) EventIdxs(i+1)]};
                end
            end
            EventIdxs = NewEventIdxs;
            Answer = questdlg('Add time limits to event limits?','Add time limits to event limits?','Yes','No','Yes');
            if strcmp(Answer,'Yes')
                AddTimeLims = true;
                Prompts = {'Start of epoch (s relative to first event) (E.g. -0.2 means 200 ms before first event, 0 means onset of first event)'
                           'End of epoch (s relative to second event) (E.g. 1.8 means 1.8 s after second event)'};
                if numel(EventIdxs) > 2
                    Answer = questdlg('Add the same relative time limits for all selected events?','Add the same relative time limits for all selected events?','Yes','No','No');
                    if strcmp(Answer,'Yes')
                        Answer = inputdlg(Prompts);
                        Lims = [str2double(Answer{1}) str2double(Answer{2})];
                        SameForEach = true;
                    else
                        SameForEach = false;
                    end
                end
            else
                AddTimeLims = false;
            end
            for EventIdx = EventIdxs
                if AddTimeLims
                    if ~SameForEach
                        Answer = inputdlg(Prompts);
                        Lims = [str2double(Answer{1}) str2double(Answer{2})];
                    end
                else
                    Lims = [0 0];
                end
                Epochs(numel(Epochs)+1).EpochType = 'Between events';
                Epochs(end).EventType = {EYE.event(EventIdx{:}).type};
                Epochs(end).InstanceN = [sum(strcmp({EYE.event(1:EventIdx{:}(1)).type},EYE.event(EventIdx{:}(1)).type)) sum(strcmp({EYE.event(1:EventIdx{:}(2)).type},EYE.event(EventIdx{:}(2)).type))];
                Epochs(end).Lims = Lims;
            end
        end
    end
end

end