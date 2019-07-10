
function out = getactiveidx

global userInterface;

out = getfield(get(userInterface, 'UserData'), 'activeEyeDataIdx');

end