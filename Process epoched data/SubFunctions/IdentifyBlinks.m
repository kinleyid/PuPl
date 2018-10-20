function BlinkIdx = IdentifyBlinks(EYE,EventIdx)

% Stretches of at least 100 ms where either stream is missing a point are
% marked as blinks.

HundredMsSampleLength = round(EYE.srate/10);

LData = EYE.pupilL(:,:,EventIdx);
RData = EYE.pupilR(:,:,EventIdx);
%{
BothNanIdx = isnan(LData) & isnan(RData);
BlinkIdx = false(size(BothNanIdx));
for StartIdx = 1:length(BothNanIdx)
    EndIdx = StartIdx + HundredMsSampleLength;
    if EndIdx > length(BothNanIdx)
        break
    end
    PercentMissing100ms = nnz(BothNanIdx(StartIdx:EndIdx))/length(StartIdx:EndIdx);
    if PercentMissing100ms >= 0.9
        BlinkIdx(round(mean([StartIdx EndIdx]))) = true;
    end
end
%}
EitherNanIdx = isnan(LData) | isnan(RData);

BlinkIdx = false(size(EitherNanIdx));
C = 0; % count
for i = 1:length(EitherNanIdx)
    if EitherNanIdx(i)
        if C == 0
            StartIdx = i;
            EndIdx = i;
        else
            EndIdx = i;
        end
        C = C + 1;
    else
        if C >= HundredMsSampleLength
            BlinkIdx(StartIdx:EndIdx) = true;
        end
        C = 0;
    end
end