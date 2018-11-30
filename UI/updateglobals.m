function updateglobals(varargin)

in = varargin{1};

if isempty(in)
    return
end

global userInterface eyeData eventLogs

dataType = in(1).type;
if ~isempty(in)
    if strcmp(dataType, 'eye data')
        currStruct = eyeData;
        activeIdx = userInterface.UserData.activeEyeDataIdx;
    elseif strcmp(dataType, 'event logs')
        currStruct = eventLogs;
        activeIdx = userInterface.UserData.activeEventLogsIdx;
    end
    if ~isempty(currStruct)
        % Create empty fields if necessary so that structs can still be in an array
        [currStruct, in] = fieldconsistency(currStruct, in);
        if any(strcmpi(varargin, 'append'))
            currStruct = [currStruct in];
        else
            currStruct(activeIdx) = in;
        end
    else
        currStruct = in;
    end
    if strcmp(dataType, 'eye data')
        eyeData = currStruct;
        userInterface.UserData.activeEyeDataIdx = activeIdx;
    elseif strcmp(dataType, 'event logs')
        eventLogs = currStruct;
        userInterface.UserData.activeEventLogsIdx = activeIdx;
    end
end

update_UI

end