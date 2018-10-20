function Baselines = GetBaselines(EYE)

Baselines = [];

UniqueEpochTypes = [];
for i = 1:length(EYE.epochs)
    New = true;
    for j = 1:length(UniqueEpochTypes)
        if isequal(EYE.epochs(i).EventType,UniqueEpochTypes{j})
            New = false;
            break
        end
    end
    if New
        UniqueEpochTypes = [UniqueEpochTypes {EYE.epochs(i).EventType}];
    end
end

UniqueEpochTypeNames = {};
for i = 1:length(UniqueEpochTypes)
    if length(UniqueEpochTypes{i}) == 1
        UniqueEpochTypeNames(i) = {sprintf('Defined using %s',UniqueEpochTypes{i}{1})};
    else
        UniqueEpochTypeNames(i) = {sprintf('Defined using %s and %s',UniqueEpochTypes{i}{1},UniqueEpochTypes{i}{2})};
    end
end

RemainingEpochTypeNames = UniqueEpochTypeNames;

CorrectionTypes = {'Compute percent dilation from baseline average' 'Subtract baseline average' 'No baseline correction'};
Question = 'Use the same type of baseline correction for each baseline?';
Answer = questdlg(Question,Question,'Yes','No','Yes');
if strcmp(Answer,'Yes')
    Question = 'Type of baseline correction?';
    Correction = questdlg(Question,Quesiton,CorrectionTypes,CorrectionTypes{1});
	SameCorrection = true;
else
    SameCorrection = false;
end

while numel(RemainingEpochTypeNames) > 0
    Answer = questdlg('Add a baseline period?','Add a baseline period?','Yes','No','Yes');
    if strcmp(Answer,'Yes')
        Answer = questdlg('Define the baseline how?','Define the baseline how?','Time limits relative to an event','Between events','Time limits relative to an epoch','Time limits relative to an event');
        if strcmp(Answer,'Time limits relative to an event')
            EventIdx = listdlg('PromptString','Relative to which event?',...
                               'ListString',{EYE.event.type});
            Prompts = {'Start of baseline (s relative to event) (E.g. -0.2 means 200 ms before event, 0 means onset of event)'
                       'End of epoch (s relative to event) (E.g. 1.8 means 1.8 s after event)'};
            Answer = inputdlg(Prompts);
            Lims = [str2double(Answer{1}) str2double(Answer{2})];
            if ~SameCorrection
                Question = 'Type of baseline correction?';
                Correction = questdlg(Question,Quesiton,CorrectionTypes,CorrectionTypes{1});
            end
            Baselines(numel(Baselines)+1).Type = 'Time limits relative to an event';
            Baselines(end).Correction = Correction;
            Baselines(end).Info = [];
            Baselines(end).Info.Lims = Lims;
            Baselines(end).Info.EventType = {EYE.event(EventIdx).type};
            Baselines(end).Info.InstanceN = sum(strcmp({EYE.event(1:EventIdx).type},EYE.event(EventIdx).type));
            EpochTypeIdx = listdlg('PromptString','Correct which epochs using this baseline?',...
                                'ListString',RemainingEpochTypeNames,...
                                'ListSize',[800,250]);
            Baselines(end).Info.EpochTypes = RemainingEpochTypeNames(EpochTypeIdx);
        elseif strcmp(Answer,'Between events')
            EventIdx = listdlg('PromptString','Between which events?',...
                               'ListString',{EYE.event.type});
            
            Prompts = {'Start of baseline (s relative to first event) (E.g. -0.2 means 200 ms before first event, 0 means onset of second event)'
                       'End of epoch (s relative to event) (E.g. 1.8 means 1.8 s after event)'};
            Answer = inputdlg(Prompts);
            Lims = [str2double(Answer{1}) str2double(Answer{2})];
            if ~SameCorrection
                Question = 'Type of baseline correction?';
                Correction = questdlg(Question,Quesiton,CorrectionTypes,CorrectionTypes{1});
            end
            Baselines(numel(Baselines)+1).Type = 'Between events';
            Baselines(end).Info = [];
            Baselines(end).Info.Lims = Lims;
            Baselines(end).Info.EventTypes = {EYE.event(EventIdx).type};
            Baselines(end).Info.InstanceN = [sum(strcmp({EYE.event(1:EventIdx(1)).type},EYE.event(EventIdx(1)).type)) sum(strcmp({EYE.event(1:EventIdx(2)).type},EYE.event(EventIdx(2)).type))];
            EpochTypeIdx = listdlg('PromptString','Correct which epochs using this baseline?',...
                                'ListString',RemainingEpochTypeNames,...
                                'ListSize',[800,250]);
            Baselines(end).Info.EpochTypes = RemainingEpochTypeNames(EpochTypeIdx);
        elseif strcmp(Answer,'Time limits relative to an epoch')
            EpochTypeIdx = listdlg('PromptString','Limits relative to which type of epoch?',...
                                'ListString',RemainingEpochTypeNames,...
                                'ListSize',[800,250]);
            Prompts = {'Start of baseline (s relative to first event) (E.g. -0.2 means 200 ms before first event, 0 means onset of second event)'
                       'End of epoch (s relative to event) (E.g. 1.8 means 1.8 s after event)'};
            Answer = inputdlg(Prompts);
            Lims = [str2double(Answer{1}) str2double(Answer{2})];
            Baselines(numel(Baselines)+1).Type = 'Time limits relative to an epoch';
            Baselines(end).Info = [];
            Baselines(end).Info.EpochTypes = RemainingEpochTypeNames(EpochTypeIdx);
            Baselines(end).Info.Lims = Lims;
        else
            continue
        end
        RemainingEpochTypeNames(EpochTypeIdx) = [];
    end
    
end