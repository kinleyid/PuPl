function out = getactive(dataType)

global userInterface

switch strrep(lower(dataType), ' ', '')
    case 'eyedata'
        out = subsref(...
            evalin('base', 'eyeData'),...
        struct('type', '()', 'subs', {{userInterface.UserData.activeEyeDataIdx}}));
    case 'eventlogs'
        out = subsref(...
            evalin('base', 'eventLogs'),...
        struct('type', '()', 'subs', {{userInterface.UserData.activeEventLogsIdx}}));
end

end