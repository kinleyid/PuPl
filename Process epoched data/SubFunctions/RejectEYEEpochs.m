function EYE = RejectEYEEpochs(EYE,RejThresh)

fprintf('Marking epochs for rejection...');
if ~isfield(EYE,'reject')
    EYE.reject = false(1,length(EYE.epochs));
end
for EpochIdx = 1:length(EYE.epochs)
    PupilLR = [EYE.epochdata(EpochIdx).pupilL; EYE.epochdata(EpochIdx).pupilR];
    if nnz(isnan(PupilLR))/numel(PupilLR) >= RejThresh
        EYE.reject(EpochIdx) = true;
    end
end

fprintf('done.\n')
fprintf('%d/%d trials were rejected for having at least %.0f%% missing points.\n',nnz(EYE.reject),length(EYE.reject),100*RejThresh)