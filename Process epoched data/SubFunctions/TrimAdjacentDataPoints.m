function EYEout = TrimAdjacentDataPoints(EYE)

fprintf('Trimming data points adjacent to missing ones... ');

nAdjToTrim = round(EYE.srate/30);
for EpochIdx = 1:length(EYE.epochs)
    LData = EYE.epochdata(EpochIdx).pupilL;
    RData = EYE.epochdata(EpochIdx).pupilR;
    BlinkIdx = IdentifyBlinks(EYE,EpochIdx);
    LData(ShiftBothDirs(BlinkIdx,nAdjToTrim)) = NaN;
    RData(ShiftBothDirs(BlinkIdx,nAdjToTrim)) = NaN;
    EYE.pupilL(:,:,EpochIdx) = LData;
    EYE.pupilR(:,:,EpochIdx) = RData;
end

EYEout = EYE;
fprintf('Done.\n')
end
function Out = ShiftBothDirs(In,n)

In = In(:)';

Out = In | [false(1,n) In(1:end-n)] | [In(n+1:end) false(1,n)];

end