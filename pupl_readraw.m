function outStruct = pupl_readraw(dataType, fileName, fileDirectory, fileFormat)

%   Inputs
% dataType--'eye data' or 'event logs'
% fileName--char
% fileDirectory--char
% fileFormat--char, specifies the source of the data
%
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
%    NB
% Missing data points should be filled in with NaN
% Timestamps should be in seconds
% Eye data always starts at time 0, latency 1

[~, name] = fileparts(fileName);

fprintf('Loading %s...\n', fileName);

switch dataType
    case 'eye data'
        switch lower(fileFormat)
            case 'tobii excel files'
                % GET GAZE COORDINATES

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

            case 'xdf files'
        
                % Ensure that the recording starts at time 0, latency 1
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
                    fprintf('Assuming channel %d (labelled %s) is left pupil diameter\n', find(leftIdx), channelNames{leftIdx});
                    fprintf('Assuming channel %d (labelled %s) is right diameter\n', find(rightIdx), channelNames{rightIdx});
                    data = struct(...
                        'left', double(eyeDataStruct.time_series(leftIdx, :)),...
                        'right', double(eyeDataStruct.time_series(rightIdx, :)));

                    gazeIdx = (cellfun(@(x) ~isempty(strfind(x, 'screen')), channelNames)...
                        | cellfun(@(x) ~isempty(strfind(x, 'gaze')), channelNames));

                    xIdx = gazeIdx & cellfun(@(x) ~isempty(strfind(x, 'x')), channelNames);
                    yIdx = gazeIdx & cellfun(@(x) ~isempty(strfind(x, 'y')), channelNames);

                    fprintf('Assuming channel %d (labelled %s) is gaze x coordinate\n', find(xIdx), channelNames{xIdx});
                    fprintf('Assuming channel %d (labelled %s) is gaze y coordinate\n', find(yIdx), channelNames{yIdx});

                    gaze = struct(...
                        'x', double(eyeDataStruct.time_series(xIdx, :)),...
                        'y', double(eyeDataStruct.time_series(yIdx, :)));

                    eyeDataT0 = eyeDataStruct.time_stamps(1);

                end

                if any(strcmpi(streamTypes, 'Markers'))

                    eventDataStruct = streams{strcmpi(streamTypes, 'Markers')};

                    emptyIdx = cellfun(@isempty, eventDataStruct.time_series);            
                    eventDataStruct.time_series(emptyIdx) = [];
                    eventDataStruct.time_stamps(emptyIdx) = [];

                    events = eventDataStruct.time_series;
                    times = double(eventDataStruct.time_stamps - eyeDataT0);
                    latencies = round(times*srate + 1);

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
            'gaze', gaze,...
            'event', event,...
            'epoch', [],...
            'bin', [],...
            'cond', [],...
            'isBlink', false(size(data.left)));
    
    case 'event logs'
        switch lower(fileFormat)
            case 'noldus excel files'
                [~, ~, R] = xlsread([fileDirectory '\\' fileName]);
                eventTypes = R(2:end, strcmp(R(1, :), 'Behavior'));
                modifiers = find(~cellfun(@isempty, (regexp(R(1, :), 'Modifier*'))));
                for modifierIdx = modifiers
                    eventTypes = strcat(eventTypes, R(2:end, modifierIdx));
                end
                eventTypes = strcat(eventTypes,R(2:end, strcmp(R(1, :), 'Event_Type')));
                eventTimes = cell2mat(R(2:end, strcmp(R(1,:), 'Time_Relative_sf')));
            case 'e-dataaid excel files'        
                [~, ~, R] = xlsread([fileDirectory '\\' fileName]);
                nTrials = size(R, 1) - 2;
                eventTimes = reshape(cell2mat(R(3:end, :)), [], 1);
                eventTypes = {};
                for i = 1:size(R, 2)
                    eventTypes = cat(1, eventTypes, repmat(R(2, i), nTrials, 1));
                end
                eventTypes(isnan(eventTimes)) = [];
                eventTimes(isnan(eventTimes)) = [];
            case 'xdf files'
                streams = load_xdf([fileDirectory '\\' fileName]);
                streamTypes = cellfun(@(x) x.info.type, streams, 'un', 0);
                if any(strcmpi(streamTypes, 'Markers'))
                    error('No event data in this xdf file')
                else
                    eventDataStruct = streams{strcmpi(streamTypes, 'Markers')};
                    emptyIdx = cellfun(@isempty, eventDataStruct.time_series);            
                    eventDataStruct.time_series(emptyIdx) = [];
                    eventDataStruct.time_stamps(emptyIdx) = [];
                    eventTypes = eventDataStruct.time_series;
                    eventTimes = double(eventDataStruct.time_stamps); 
                end
            case 'presentation log files'
                fID = fopen([fileDirectory '\\' fileName]);
                
                nCols = NaN;
                eventTimes = [];
                eventTypes = [];
                while true
                    currLine = strsplit(fgetl(fID), '\t');
                    if any(strcmpi(currLine, 'Event Type'))
                        if ~isnan(nCols) % We're at the second half of the file
                            break % So exit
                        end
                        nCols = length(currLine);
                        timeIdx = strcmpi(currLine, 'Time');
                        typeIdx = [
                            find(strcmpi(currLine, 'Event Type'))...
                            find(strcmpi(currLine, 'Code'))...
                            find(strcmpi(currLine, 'Stim Type'))];
                        continue
                    end
                    if length(currLine) ~= 1
                        eventTimes = cat(2, eventTimes, str2double(currLine{timeIdx})/10/1000); % Presentation records time in 10ths of milliseconds
                        eventTypes = cat(2, eventTypes, {strcat(currLine{typeIdx(typeIdx <= length(currLine))})});
                    end
                end
        end

        fprintf('Found %d events\n', numel(eventTypes))
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