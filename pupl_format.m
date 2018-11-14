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

if isempty(p.Results.type)
    dataTypeOptions = {
        'eye data'
        'event logs'};
    dataType = dataTypeOptions(listdlg('PromptString', 'Data type',...
        'ListString', dataTypeOptions));
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
            'E-DataAid Excel files'
        };
    end
    dataFormat = formatOptions{listdlg('PromptString', 'File format',...
        'ListString', formatOptions)};
else
    dataFormat = p.Results.format;
end

if isempty(p.Results.directory) || isempty(p.Results.filenames)
    % uiwait(msgbox(sprintf('Select the %s to format', dataFormat)));
    [dataFiles, dataDirectory] = uigetfile('./*.*', ...
        sprintf('Select the %s', dataFormat),...
            'MultiSelect','on');
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
        
        streams = load_xdf([fileDirectory '\\' fileName]);
        
        srate = str2double(streams{1}.info.nominal_srate);
        
        if strcmp(streams{1,1}.info.name,'EyeTribe') && strcmp(streams{1,2}.info.name,'Presentation')
            tempsw_c1 = struct2cell(streams{1,1});
            tempsw_c2 = struct2cell(streams{1,2});
        elseif strcmp(streams{1,1}.info.name,'Presentation') && strcmp(streams{1,2}.info.name,'EyeTribe')
            tempsw_c1 = struct2cell(streams{1,2});
            tempsw_c2 = struct2cell(streams{1,1});
        else
            disp('ERROR!!! --> Missing EyeTribe or Presentation Data Streams in XDF file!!!');
            return;
        end

        % NOTE that LSL load_xdf coordinates sample timing between these streams on import above!!!...

        tempsw_c1_3 = tempsw_c1{3,1}; % eyetribe tracker data, 8 columns
        tempsw_c1_4 = tempsw_c1{4,1}; % eyetribe time stamps (tracker samples)
        tempsw_c2_2 = tempsw_c2{2,1}; % Presentation marker info
        tempsw_c2_3 = tempsw_c2{3,1}; % Presentation time stamps for markers

        % put pupil data & timestamps in a single cell array, with a spare final row...
        tempsw_pupil_data_v1 = [tempsw_c1_3 ; tempsw_c1_4];
        tempsw_filler2 = ones(1, length(tempsw_pupil_data_v1) ) * 0; 
        tempsw_pupil_data_v2 = [ tempsw_pupil_data_v1 ; tempsw_filler2 ];
        pupil_data_v3 = num2cell(tempsw_pupil_data_v2);

        % make arrays (not cells) of pupil data (so have numbers only)...
        % --> EXCEPT for markers - THOSE need to be cells, to have ASCII data etc in there
        % we will use these to operate on as we do various filtering etc...
        pupil_data_Left_v1 = cell2mat( pupil_data_v3(5,1:end) );
        pupil_data_Right_v1 = cell2mat( pupil_data_v3(8,1:end) );
        
        puplLeft = pupil_data_Left_v1;
        puplRight = pupil_data_Right_v1;
        puplLeft(puplLeft == 0) = NaN;
        puplRight(puplRight == 0) = NaN;
        
        data = struct(...
            'left', double(puplLeft),...
            'right', double(puplRight));

        % get event markers & timestamps in a single cell array...
        tempsw_marker_values = tempsw_c2_2;
        tempsw_marker_times = tempsw_c2_3 - str2double(streams{1}.info.first_timestamp);
        
        times = num2cell(tempsw_marker_times*1000);
        latencies = num2cell(round(tempsw_marker_times*1000/srate + 1));
        
        event = struct(...
            'type', tempsw_marker_values,...
            'time', times,...
            'latency', latencies);
        
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