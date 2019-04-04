
function out = dataexists(dataType)

switch dataType
    case 'eye data'
        global eyeData
        if isempty(eyeData)
            out = false;
        else
            out = true;
        end
    case 'event logs'
        global eventLogs
        if isempty(eventLogs)
            out = false;
        else
            out = true;
        end
end

end