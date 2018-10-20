
function BaselineCorrection
Question = 'Select the epoched eye data files for baseline correcting';
uiwait(msgbox(Question));
[Filenames,Path] = uigetfile('..\..\..\*.mat',...
    Question,...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

Question = 'Select a folder to save the baseline-corrected eye data to';
uiwait(msgbox(Question));
SaveTo = uigetdir([Path '\..'],...
                  Question);


if length(Filenames) > 1
    Question = 'Define the same baselines for each file?';
    Answer = questdlg(Question,Question,'Yes','No','Yes');
    if strcmp(Answer,'Yes')
        SameForEach = true;
        MatData = load([Path '\' Filenames{1}],'-mat');
        EYE = MatData.EYE;
        
        BaselineDescriptions = GetBaselineDescriptions(EYE);
    else
        SameForEach = false;
    end
end

for Filename = Filenames
    MatData = load([Path '\' Filename{:}],'-mat');
    EYE = MatData.EYE;
    if ~SameForEach
        BaselineDescriptions = GetBaselineDescriptions(EYE);
    end
    EYE = ApplyBaselineCorrection(EYE,BaselineDescriptions); 
    fprintf('Saving [%s] to [%s]\n',Filename{:},SaveTo)
    save([SaveTo '\' EYE.name '.mat'],'EYE');
end