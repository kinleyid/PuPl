
cd SubFunctions

uiwait(msgbox('Select the epoched eye data for processing'));
[Filenames,Path] = uigetfile('..\..\..\..\*.mat',...
    'Select the epoched eye data for processing',...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

uiwait(msgbox('Select a folder to save the processed eye data to'));
SaveTo = uigetdir([Path '\..'],...
    'Select a folder to save the processed eye data to');

Answer = inputdlg('Above what percentage of missing data will epochs be rejected?',...
                  'Above what percentage of missing data will epochs be rejected?',...
                  1,{'10'});
RejThresh = str2double(Answer)/100;

[smoothN,SmoothingType] = GetMovingAverageParam(Path,Filenames);

MatData = load([Path Filenames{1}]);
EYE = MatData.EYE;
Correction = questdlg('Type of baseline correction?',...
                      'Type of baseline correction?',...
                      'Compute percentage dilation from baseline average',...
                      'Subtract baseline average',...
                      'No baseline correction','Compute percentage dilation from baseline average');
if length(Filenames) > 1
    Answer = questdlg('Use the same baselines for each file?','Use the same baselines for each file?','Yes','No','No');
    if strcmp(Answer,'Yes')
        SameForEach = true;
        Baselines = GetBaselines(EYE);
    else
        SameForEach = false;
    end
else
    SameForEach = false;
end
fprintf('\n')

for FileIdx = 1:length(Filenames)
    if ~SameForEach
        Baselines = GetBaselines(EYE);
    end
    fprintf('Processing %s\n:',Filenames{FileIdx})
    MatData = load([Path Filenames{FileIdx}]);
    EYE = MatData.EYE;
    EYE = RejectEYEEpochs(EYE,RejThresh);
    EYE = MovingAverageEyeFilter(EYE,smoothN,SmoothingType);
    % EYE = TrimAdjacentDataPoints(EYE);
    EYE = InterpolateEyeData(EYE);
    EYE = ApplyBaselineCorrection(EYE,Baselines,Correction);
    fprintf('Combining left and right pupil dilation streams...\n')
    EYE.pupilLR = (EYE.pupilL + EYE.pupilL)/2;
    [~,Name] = fileparts(Filenames{FileIdx});
    fprintf('Saving...\n\n')    
    save([SaveTo '\' Name '.mat'],'EYE');
end

cd ..