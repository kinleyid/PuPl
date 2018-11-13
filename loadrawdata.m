function outStruct = loadrawdata(dataType, fileName, fileDirectory, fileFormat)

%   Inputs
% dataType--'eye data' or 'event logs'
% fileName--char
% fileDirectory--char
% fileFormat--char, specifies the source of the data
%   Outputs
% outStruct--single struct
%   if dataType is 'eye data', outStruct has the following fields:
%       name--the file name, usually participant ID
%       data--a struct with fields 'left' and 'right'
%       urData--a clone of 'data'
%       srate--sample rate in Hz
%       event--struct array with fields 'type', 'time', and 'latency'
%   if dataType is 'event logs', outStruct has the following fields:
%       name--the file name, usually participant ID
%       event--struct array with fields 'type' and 'time'
%
% Missing data points should be filled in with NaN

[~, name] = fileparts(fileName);

if strcmpi(dataType, 'eye data')
    if strcmpi(fileFormat,'Tobii Excel files')
        
        [~ , ~, R] = xlsread([fileDirectory '\\' fileName]);
        
        timestamps = cell2mat(R(2:end, strcmp(R(1, :), 'RecordingTimestamp')));
        srate = round((length(timestamps))/((max(timestamps) - min(timestamps))/1000));
        
        data = struct(...
            'left', R(2:end, strcmp(R(1, :), 'PupilLeft')),...
            'right', R(2:end, strcmp(R(1, :), 'PupilRight')));
        for field = reshape(fieldnames(data), 1, [])
            data.(field{:})(cellfun(@isempty, data.(field{:}))) = {NaN};
            data.(field{:}) = reshape(cell2mat(data.(field{:})), 1, []);
        end
        
        [events, times] = deal({});
        for eventType = {'KeyPressEvent' 'MouseEvent' 'StudioEvent' 'ExternalEvent'}
            currEvents = R(2:end, strcmp(R(1, :), eventType{:}));
            events = cat(1, events, currEvents(~cellfun(@isempty, currEvents)));
            times = cat(1, times, timestamps(~cellfun(@isempty, currEvents)));
        end
        event = struct(...
            'type', events,...
            'time', times,...
            'latency', times/srate + 1);
        [~, I] = sort([event.time]);
        event = event(I);

    end
    
    outStruct = struct(...
        'name', name,...
        'data', data,...
        'srate', srate,...
        'urData', data,...
        'event', event);
    
elseif strcmpi(dataType, 'event logs')
    if strcmp(fileFormat,'Noldus Excel files')
        
        [~, ~, R] = xlsread([fileDirectory '\\' fileName]);
        eventTypes = R(2:end, strcmp(R(1, :), 'Behavior'));
        modifiers = find(~cellfun(@isempty, (regexp(R(1, :), 'Modifier*'))));
        for modifierIdx = modifiers
            eventTypes = strcat(eventTypes, R(2:end, modifierIdx));
        end
        eventTypes = strcat(eventTypes,R(2:end, strcmp(R(1, :), 'Event_Type')));
        eventTimes = 1000*cell2mat(R(2:end, strcmp(R(1,:), 'Time_Relative_sf')));
        
    elseif strcmp(fileFormat,'E-DataAid Excel files')
        
        [~, ~, R] = xlsread([fileDirectory '\\' fileName]);
        nTrials = size(R, 1) - 2;
        eventTimes = reshape(cell2mat(R(3:end, :)), [], 1);
        eventTypes = {};
        for i = 1:size(R, 2)
            eventTypes = cat(1, eventTypes, repmat(R(2, i), nTrials, 1));
        end
        eventTypes(isnan(eventTimes)) = [];
        eventTimes(isnan(eventTimes)) = [];
        
    end

    outStruct = struct(...
        'name', name,...
        'event', struct(...
            'type', eventTypes,...
            'time', num2cell(eventTimes)));
    [~, I] = sort([outStruct.event.time]);
    outStruct.event = outStruct.event(I);

end

end
