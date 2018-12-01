function out = getactive(dataType)

global userInterface

if strcmpi(dataType, 'eye data')
    out = subsref(...
        evalin('base', 'eyeData'),...
    struct('type', '()', 'subs', {{userInterface.UserData.activeEyeDataIdx}}));
elseif strcmpi(dataType, 'event logs')
    out = subsref(...
        evalin('base', 'eventLogs'),...
    struct('type', '()', 'subs', {{userInterface.UserData.activeEyeDataIdx}}));
end

end