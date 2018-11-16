function void = deleteData(dataType)

void = [];

global eyeData activeEyeDataIdx eventLogs activeEventLogsIdx

if strcmpi(dataType, 'eye data')
    eyeData(activeEyeDataIdx) = [];
    activeEyeDataIdx(activeEyeDataIdx) = [];
elseif strcmpi(dataType, 'event logs')
    eventLogs(activeEventLogsIdx) = [];
    activeEventLogsIdx(activeEventLogsIdx) = [];
end

end