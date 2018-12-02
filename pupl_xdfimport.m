function outStructArray = pupl_xdfimport(varargin)

% Imports eye data or event logs from xdf
%
%   Inputs
% filename--char or cell array of char
% directory--char
% as--'eye data' (default) or 'event logs'
% manual--1/true (default) or 0/false. If 1, user gets to decide which stream is which
%   Outputs
% outStructArray--struct array

outStructArray = [];

p = inputParser;
addParameter(p, 'filename', [])
addParameter(p, 'directory', '.')
addParameter(p, 'as', 'eye data')
addParameter(p, 'manual', true)
parse(p, varargin{:});

isManual = logical(p.Results.manual);

directory = p.Results.directory;

if isempty(p.Results.filename)
    [filename, directory] = uigetfile([directory '\\*.xdf'],...
        'MultiSelect', 'on');
    if isnumeric(filename)
        return
    end
else
    filename = p.Results.filename;
end
filename = cellstr(filename);

listSize = [500 300];

for fileIdx = 1:numel(filename)
    [~, name] = fileparts(filename{fileIdx});
    currStruct = struct('name', name);
    fprintf('Loading %s...\n', filename{fileIdx});
    streams = load_xdf([directory '\\' filename{fileIdx}]);
    streamTypes = cellfun(@(x) x.info.type, streams, 'un', 0);
    if isManual
        if strcmpi(p.Results.as, 'eye data')
            if ~exist('eyeDataStreamType', 'var')
                eyeDataStreamType = streamTypes(listdlg(...
                    'PromptString', 'Which stream contains the eye data?',...
                    'ListString', streamTypes,...
                    'SelectionMode', 'single',...
                    'ListSize', listSize));
            end
        end
        if ~exist('eventsStreamType', 'var')
            eventsStreamTypeOpts = [streamTypes 'none of the above'];
            eventsStreamType = eventsStreamTypeOpts(listdlg(...
                'PromptString', 'Which stream contains the event markers?',...
                'ListString', eventsStreamTypeOpts,...
                'SelectionMode', 'single',...
                'ListSize', listSize));
        end
    else
        eyeDataStreamType = 'Gaze';
        eventsStreamType = 'Markers';
    end
    
    if ~strcmpi(eventsStreamType, 'none of the above')
        eventDataStruct = streams{strcmpi(streamTypes, eventsStreamType)};
        if isempty(eventDataStruct)
            event = [];
        else
            emptyIdx = cellfun(@isempty, eventDataStruct.time_series);            
            eventDataStruct.time_series(emptyIdx) = [];
            eventDataStruct.time_stamps(emptyIdx) = [];
            events = eventDataStruct.time_series;
            times = double(eventDataStruct.time_stamps);
            fprintf('%d events found\n', numel(events));
            event = struct(...
                'type', events,...
                'time', num2cell(times));
        end
    else
        event = [];
    end
    
    if strcmpi(p.Results.as, 'eye data')
        eyeDataStruct = streams{strcmpi(streamTypes, eyeDataStreamType)};
        srate = str2double(eyeDataStruct.info.nominal_srate);
        fprintf('Nominal sample rate: %f Hz\n', srate);
        if isempty(eyeDataStruct)
            fprintf('No eye data in %s\n', filename{fileIdx});
        else
            srate = str2double(eyeDataStruct.info.nominal_srate);
            fprintf('Replacing 0s with NaNs\n')
            eyeDataStruct.time_series(eyeDataStruct.time_series == 0) = NaN;
            fprintf('Found %s channels\n', eyeDataStruct.info.channel_count)
            channelNames = cellfun(@(x) lower(x.label), eyeDataStruct.info.desc.channels.channel, 'un', 0);
            if isManual
                if ~exist('leftIdx', 'var')
                    leftIdx = listdlg(...
                        'PromptString', 'Which channel is left diameter?',...
                        'ListString', channelNames,...
                        'SelectionMode', 'single',...
                        'ListSize', listSize);
                end
                if ~exist('rightIdx', 'var')
                    rightIdx = listdlg(...
                        'PromptString', 'Which channel is right diameter?',...
                        'ListString', channelNames,...
                        'SelectionMode', 'single',...
                        'ListSize', listSize);
                end
                if ~exist('xIdx', 'var')
                    xIdx = listdlg(...
                        'PromptString', 'Which channel is gaze x coordinates?',...
                        'ListString', channelNames,...
                        'SelectionMode', 'single',...
                        'ListSize', listSize);
                end
                if ~exist('yIdx', 'var')
                    yIdx = listdlg(...
                        'PromptString', 'Which channel is gaze y coordinates?',...
                        'ListString', channelNames,...
                        'SelectionMode', 'single',...
                        'ListSize', listSize);
                end
            else
                pupilIdx = (cellfun(@(x) ~isempty(strfind(x, 'diameter')), channelNames)...
                | cellfun(@(x) ~isempty(strfind(x, 'pupil')), channelNames)...
                | cellfun(@(x) ~isempty(strfind(x, 'dilation')), channelNames))...
                    & cellfun(@(x) isempty(strfind(x, 'x')), channelNames)...
                    & cellfun(@(x) isempty(strfind(x, 'y')), channelNames);
                leftIdx = pupilIdx & cellfun(@(x) ~isempty(strfind(x, 'left')), channelNames);
                rightIdx = pupilIdx & cellfun(@(x) ~isempty(strfind(x, 'right')), channelNames);
                
                gazeIdx = (cellfun(@(x) ~isempty(strfind(x, 'screen')), channelNames)...
                    | cellfun(@(x) ~isempty(strfind(x, 'gaze')), channelNames));
                xIdx = gazeIdx & cellfun(@(x) ~isempty(strfind(x, 'x')), channelNames);
                yIdx = gazeIdx & cellfun(@(x) ~isempty(strfind(x, 'y')), channelNames);
            end
            
            fprintf('Treating channel %s as left pupil diameter\n', channelNames{leftIdx});
            fprintf('Treating channel %s as right diameter\n', channelNames{rightIdx});
            fprintf('Treating channel %s as gaze x coordinate\n', channelNames{xIdx});
            fprintf('Treating channel %s as gaze y coordinate\n', channelNames{yIdx});
            
            data = struct(...
                'left', double(eyeDataStruct.time_series(leftIdx, :)),...
                'right', double(eyeDataStruct.time_series(rightIdx, :)));
            gaze = struct(...
                'x', double(eyeDataStruct.time_series(xIdx, :)),...
                'y', double(eyeDataStruct.time_series(yIdx, :)));
            if ~isempty(event)
                % Add latencies to event markers and adjust their time
                % stamps so that time 0 is the first data sample from the
                % eye data.
                newTimes = [event.time] - eyeDataStruct.time_stamps(1);
                latencies = round(newTimes*srate + 1);
                newTimes = num2cell(newTimes);
                latencies = num2cell(latencies);
                [event.time] = newTimes{:};
                [event.latency] = latencies{:};
            end
            currStruct.data = data;
            currStruct.urData = data;
            currStruct.srate = srate;
            currStruct.gaze = gaze;
            currStruct.epoch = [];
            currStruct.bin = [];
            currStruct.cond = [];
            currStruct.isBlink = false(size(data.left));
        end
    end
    currStruct.event = event;
    
    outStructArray = [outStructArray currStruct];
end

end