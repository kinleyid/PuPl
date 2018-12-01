function out = getactiveeyedata

global eyeData userInterface
out = eyeData(userInterface.UserData.activeEyeDataIdx);

end