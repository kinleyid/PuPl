function structArray = pupl_format(varargin)

% Format eye data or event logs
%   Inputs
% type--'eye data' or 'event logs'
% filenames--cell array
% directory--char
% format--format of data

p = inputParser;
addParameter(p, 'type', [])
addParameter(p, 'filenames', [])
addParameter(p, 'directory', [])
addParameter(p, 'format', [])
parse(p, varargin{:});

structArray = [];

if isempty(p.Results.type)
    dataTypeOptions = {
        'eye data'
        'event logs'};
    dataType = dataTypeOptions(listdlg('PromptString', 'Data type',...
        'ListString', dataTypeOptions));
    if isempty(dataType)
        return
    end
else
    dataType = p.Results.type;
end

if isempty(p.Results.format)
    if strcmpi(dataType, 'eye data')
        formatOptions = {
            'Tobii Excel files'
            'XDF files'
        };
    elseif strcmpi(dataType, 'event logs')
        formatOptions = {
            'Noldus Excel files'
            % 'Presentation .log files'
            'XDF files'
            'E-DataAid Excel files'
        };
    end
    dataFormat = formatOptions(listdlg('PromptString', 'File format',...
        'ListString', formatOptions));
    if isempty(dataFormat)
        return
    end
else
    dataFormat = p.Results.format;
end
dataFormat = char(dataFormat);

if isempty(p.Results.directory) || isempty(p.Results.filenames)
    % uiwait(msgbox(sprintf('Select the %s to format', dataFormat)));
    [dataFiles, dataDirectory] = uigetfile('./*.*', ...
        sprintf('Select the %s', dataFormat),...
            'MultiSelect','on');
    if dataFiles == 0
        return
    end
else
    dataFiles = p.Results.filenames;
    dataDirectory = p.Results.directory;
end
dataFiles = cellstr(dataFiles);

structArray = cellfun(@(file) readraw(dataType, file, dataDirectory, dataFormat), dataFiles);

end

function outStruct = readraw(dataType, fileName, fileDirectory, fileFormat)

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
            'latency', {cell2mat(times)/srate + 1});
        [~, I] = sort([event.time]);
        event = event(I);

    elseif strcmpi(fileFormat,'XDF files')
        
        % Ensure that the recording starts at time 0, latency 1
        fprintf('Now loading %s\n', fileName);
        streams = load_xdf([fileDirectory '\\' fileName]);
        streamTypes = cellfun(@(x) x.info.type, streams, 'un', 0);
        
        if ~any(strcmpi(streamTypes, 'Gaze'))
            error('No eye data to be found in this xdf file');
        else
            eyeDataStruct = streams{strcmpi(streamTypes, 'Gaze')};

            srate = str2double(eyeDataStruct.info.nominal_srate);
            
            eyeDataStruct.time_series(eyeDataStruct.time_series == 0) = NaN;
            fprintf('Found %s channels\n', eyeDataStruct.info.channel_count)
            channelNames = cellfun(@(x) lower(x.label), eyeDataStruct.info.desc.channels.channel, 'un', 0);
            
            pupilIdx = (cellfun(@(x) ~isempty(strfind(x, 'diameter')), channelNames)...
                    | cellfun(@(x) ~isempty(strfind(x, 'pupil')), channelNames)...
                    | cellfun(@(x) ~isempty(strfind(x, 'dilation')), channelNames))...
                & cellfun(@(x) isempty(strfind(x, 'x')), channelNames)...
                & cellfun(@(x) isempty(strfind(x, 'y')), channelNames);
            leftIdx = pupilIdx & cellfun(@(x) ~isempty(strfind(x, 'left')), channelNames);
            rightIdx = pupilIdx & cellfun(@(x) ~isempty(strfind(x, 'right')), channelNames);
            fprintf('Assuming channel %d (labelled %s) is left dilation\n', find(leftIdx), channelNames{leftIdx});
            fprintf('Assuming channel %d (labelled %s) is right dilation\n', find(rightIdx), channelNames{rightIdx});
            data = struct(...
                'left', double(eyeDataStruct.time_series(leftIdx, :)),...
                'right', double(eyeDataStruct.time_series(rightIdx, :)));
            
            t0 = eyeDataStruct.time_stamps(1)*1000; % ms
            
        end
        
        if any(strcmpi(streamTypes, 'Markers'))
            
            fprintf('Found event data as well\n');
            eventDataStruct = streams{strcmpi(streamTypes, 'Markers')};

            emptyIdx = cellfun(@isempty, eventDataStruct.time_series);            
            eventDataStruct.time_series(emptyIdx) = [];
            eventDataStruct.time_stamps(emptyIdx) = [];
            
            events = eventDataStruct.time_series;
            times = double(eventDataStruct.time_stamps*1000 - t0); % ms
            latencies = round(times/1000*srate + 1);
            
            fprintf('%d events found\n', numel(events));
            
            event = struct(...
                'type', events,...
                'time', num2cell(times),...
                'latency', num2cell(latencies));
        end
        
    end
    
    outStruct = struct(...
        'name', name,...
        'type', 'eye data',...
        'data', data,...
        'srate', srate,...
        'urData', data,...
        'event', event,...
        'epoch', [],...
        'bin', [],...
        'cond', []);
    
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
        
    elseif strcmp(fileFormat, 'E-DataAid Excel files')
        
        [~, ~, R] = xlsread([fileDirectory '\\' fileName]);
        nTrials = size(R, 1) - 2;
        eventTimes = reshape(cell2mat(R(3:end, :)), [], 1);
        eventTypes = {};
        for i = 1:size(R, 2)
            eventTypes = cat(1, eventTypes, repmat(R(2, i), nTrials, 1));
        end
        eventTypes(isnan(eventTimes)) = [];
        eventTimes(isnan(eventTimes)) = [];
        
    elseif strcmp(fileFormat, 'XDF files')
        
        streams = load_xdf([fileDirectory '\\' fileName]);
        
        streamTypes = cellfun(@(x) x.info.name, streams, 'un', 0);
        eventLogTypes = {'Presentation' 'Other possible sources go here'};
        
        if any(ismember(streamTypes, eventLogTypes))    
            eventDataStruct = streams{ismember(streamTypes, eventLogTypes)};

            emptyIdx = cellfun(@isempty, eventDataStruct.time_series);            
            eventDataStruct.time_series(emptyIdx) = [];
            eventDataStruct.time_stamps(emptyIdx) = [];
            
            eventTypes = eventDataStruct.time_series;
            eventTimes = double(eventDataStruct.time_stamps*1000); 
        end
    end

    outStruct = struct(...
        'name', name,...
        'type', 'event logs',...
        'event', struct(...
            'type', eventTypes,...
            'time', num2cell(eventTimes)));
    [~, I] = sort([outStruct.event.time]);
    outStruct.event = outStruct.event(I);

end

end