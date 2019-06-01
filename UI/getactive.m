function out = getactive(dataType)

global userInterface

switch strrep(lower(dataType), ' ', '')
    case 'eyedata'
        out = subsref(...
            evalin('base', 'eyeData'),...
        struct('type', '()', 'subs', {{getfield(get(userInterface, 'UserData'), 'activeEyeDataIdx')}}));
end

end