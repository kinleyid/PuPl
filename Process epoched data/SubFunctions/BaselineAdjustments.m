function EYE = BaselineAdjustments(EYE,CorrLims,Correction)

EYE.epochinfo.correction = Correction;

for i = 1:length(EYE.event)
    PreEvent = 0:-1/EYE.srate:CorrLims(1);
    PostEvent = 0:1/EYE.srate:CorrLims(2);
    EYE.epochinfo.baselinetimes = [fliplr(PreEvent) PostEvent(2:end)];
    EYE.epochinfo.baselinelatencies = find(ismember(EYE.epochinfo.times,EYE.epochinfo.baselinetimes));
    if strcmp(Correction,'Compute percentage dilation from baseline average')
        EYE.pupilL(:,:,i) = (EYE.pupilL(:,:,i)/nanmean(EYE.pupilL(:,EYE.epochinfo.baselinelatencies,i))-1)*100;
        EYE.pupilR(:,:,i) = (EYE.pupilR(:,:,i)/nanmean(EYE.pupilR(:,EYE.epochinfo.baselinelatencies,i))-1)*100;
    elseif strcmp(Correction,'Subtract baseline average')
        EYE.pupilL(:,:,i) = (EYE.pupilL(:,:,i) - nanmean(EYE.pupilL(:,EYE.epochinfo.baselinelatencies,i))-1)*100;
        EYE.pupilR(:,:,i) = (EYE.pupilR(:,:,i) - nanmean(EYE.pupilR(:,EYE.epochinfo.baselinelatencies,i))-1)*100;
    end
end