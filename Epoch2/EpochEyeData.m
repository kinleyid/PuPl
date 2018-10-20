function EpochEyeData
Question = 'Select the eye data for epoching';
uiwait(msgbox(Question));
[Filenames,Path] = uigetfile('..\..\..\*.mat',...
    Question,...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

Question = 'Select a folder to save the epoched eye data to';
uiwait(msgbox(Question));
SaveTo = uigetdir([Path '\..'],...
                  Question);

fprintf('Adding ''start of recording'' and ''end of recording'' to event records if necessary...\n');
for Filename = Filenames
    MatData = load([Path '\' Filename{:}],'-mat');
    EYE = MatData.EYE;
    if ~strcmp(EYE.event(1).type,'Start of recording')
        NewEvent = [];
        NewEvent.type = 'Start of recording';
        NewEvent.latency = 1;
        EYE.event(2:end+1) = EYE.event; % Preserves orientation of vector
        EYE.event(1) = NewEvent;
    end
    if ~strcmp(EYE.event(end).type,'End of recording')
        NewEvent = [];
        NewEvent.type = 'End of recording';
        NewEvent.latency = numel(EYE.data.left);
        EYE.event(end+1) = NewEvent;
    end
    save([Path '\' Filename{:}],'EYE');
end

if length(Filenames) > 1
    Answer = questdlg('Define the same epochs for each file?','Define the same epochs for each file?','Yes','No','Yes');
    if strcmp(Answer,'Yes')
        SameForEach = true;
        MatData = load([Path '\' Filenames{1}],'-mat');
        EYE = MatData.EYE;
        fprintf('Defining epochs for all files...\n')
        
        EpochDescriptions = GetEpochDescriptions(EYE);
    else
        SameForEach = false;
    end
end

Question = 'Above what percentage of missing data should epochs be rejected?';
Answer = inputdlg(Question,Question,1,{'10'});
RejThresh = str2double(Answer)/100;

for Filename = Filenames
    MatData = load([Path '\' Filename{:}],'-mat');
    EYE = MatData.EYE;
    if ~SameForEach
        fprintf('Defining epochs for [%s]...\n',EYE.name)
        uiwait(msgbox(sprintf('Now processing %s',Filename{:})));
        EpochDescriptions = GetEpochDescriptions(EYE);
    end
    EYE = UseEpochDescriptions(EYE,EpochDescriptions,RejThresh);
    fprintf('Saving [%s] to [%s]\n\n',Filename{:},SaveTo)
    save([SaveTo '\' EYE.name '.mat'],'EYE');
end