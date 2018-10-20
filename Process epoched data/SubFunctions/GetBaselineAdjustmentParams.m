function [CorrLims,Correction] = GetBaselineAdjustmentParams(EYE)

Prompts = {'Start of baseline period (s) (E.g. -0.2 means 200 ms before event, 0 means onset of event)'
           'End of baseline period (s) (E.g. 1.8 means 1.8 s after event)'};
Answers = inputdlg(Prompts,'Baseline correction limits',1,{num2str(EYE.epochinfo.times(1)),'0'});
CorrLims = [str2double(Answers{1}) str2double(Answers{2})];

Correction = questdlg('Type of baseline correction?',...
        'Type of baseline correction?',...
        'Compute percentage dilation from baseline average','Subtract baseline average','No baseline correction','Compute percentage dilation from baseline average');