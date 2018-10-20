function EYE = InterpolateEyeData(EYE)

fprintf('Interpolating missing data...')
for EpochIdx = 1:length(EYE.epochs)
    TempLData = EYE.epochdata(EpochIdx).pupilL;
    TempRData = EYE.epochdata(EpochIdx).pupilR;
    if all(isnan(TempLData)) || all(isnan(TempRData))
        continue % Interpolation would probably be screwy
    end
    EYE.epochdata(EpochIdx).pupilL(isnan(EYE.epochdata(EpochIdx).pupilL)) = interp1(find(~isnan(TempLData)), TempLData(~isnan(TempLData)), find(isnan(TempLData)) );
    EYE.epochdata(EpochIdx).pupilR(isnan(EYE.epochdata(EpochIdx).pupilR)) = interp1(find(~isnan(TempRData)), TempRData(~isnan(TempRData)), find(isnan(TempRData)) );
end

fprintf('done.\n')