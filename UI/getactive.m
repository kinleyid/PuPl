function out = getactive(dataType)

global userInterface

switch lower(dataType)
    case 'eye data'
        out = subsref(...
            evalin('base', 'eyeData'),...
        struct('type', '()', 'subs', {{userInterface.UserData.activeEyeDataIdx}}));
    case 'event logs'
        out = subsref(...
            evalin('base', 'eventLogs'),...
        struct('type', '()', 'subs', {{userInterface.UserData.activeEventLogsIdx}}));
end

end