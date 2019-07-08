
function EYE = sub_xdfimport(fullpath)

%% Get raw and identify streams

streams = load_xdf(fullpath);

% Figure out which streams are which
streamTypes = cellfun(@(x) x.info.type, streams, 'UniformOutput', false);
persistent eyeDataStream eventsStream eyeDataChans; % So that the user doesn't need to make the same selection over and over
if isempty(eyeDataStream)
    sel = listdlg(...
        'PromptString', sprintf('Which stream is eye data?'),...
        'ListString', streamTypes,...
        'SelectionMode', 'single');
    if isempty(sel)
        return
    end
    eyeDataStream = streamTypes(sel);
end
if isempty(eventsStream)
    eventsStreamOpts = [streamTypes 'none of the above'];
    sel = listdlg(...
        'PromptString', sprintf('Which stream is event markers?'),...
        'ListString', eventsStreamOpts,...
        'SelectionMode', 'single');
    if isempty(sel)
        return
    end
    eventsStream = eventsStreamOpts(sel);
end

%% Get events

if ~strcmpi(eventsStream, 'none of the above') % An events stream exists
    eventDataStruct = streams{strcmpi(streamTypes, eventsStream)};
    if isempty(eventDataStruct)
        event = [];
    else
        emptyidx = cellfun(@isempty, eventDataStruct.time_series);            
        eventDataStruct.time_series(emptyidx) = [];
        eventDataStruct.time_stamps(emptyidx) = [];
        eventtypes = eventDataStruct.time_series;
        eventtimes = double(eventDataStruct.time_stamps); % Are these in seconds?
        event = 1; % isempty(event) is called later--this is a bit of duct tape
    end
else
    event = [];
end

%% Get eye data

eyeDataStruct = streams{strcmpi(streamTypes, eyeDataStream)};
if isempty(eyeDataStruct)
    error('No eye data in %s\n', fullpath);
else
    srate = sscanf(eyeDataStruct.info.nominal_srate, '%d');
    % Replace zeros with NaNs
    eyeDataStruct.time_series(eyeDataStruct.time_series < eps) = NaN;
    % Get channel names
    channelNames = cellfun(@(x) lower(x.label), eyeDataStruct.info.desc.channels.channel, 'UniformOutput', false);
    channelOpts = [channelNames 'None of the above'];
    %% Get pupil size
    diam = [];
    pre = 'pupil size';
    for side = {'left' 'right'}
        str = sprintf('%s %s', side{:}, pre);
        field = strrep(str, ' ', '');
        if ~isfield(eyeDataChans, field)
            sel = listdlg(...
                'PromptString', sprintf('Which channel is %s?', str),...
                'ListString', channelOpts,...
                'SelectionMode', 'single');
            if isempty(sel)
                return
            elseif strcmpi(channelOpts{sel}, 'none of the above')
                continue
            else
                eyeDataChans.(field) = channelOpts{sel};
            end
        end
        idx = strcmp(channelNames, eyeDataChans.(field));
        diam.(side{:}) = double(eyeDataStruct.time_series(idx, :));
    end
    %% Get gaze position
    gaze = [];
    pre = 'gaze';
    for side = {'left' 'right'}
        for ax = {'x' 'y'}
            str = sprintf('%s %s %s', side{:}, pre, ax{:});
            field = strrep(str, ' ', '');
            if ~isfield(eyeDataChans, field)
                sel = listdlg(...
                    'PromptString', sprintf('Which channel is %s?', str),...
                    'ListString', channelOpts,...
                    'SelectionMode', 'single');
                if isempty(sel)
                    return
                elseif strcmpi(channelOpts{sel}, 'none of the above')
                    continue
                else
                    eyeDataChans.(field) = channelOpts{sel};
                end
            end
            idx = strcmp(channelNames, eyeDataChans.(field));
            gaze.(ax{:}).(side{:}) = double(eyeDataStruct.time_series(idx, :));
        end
    end
    
    %% Now that we know which struct is the eye data, compute latencies
    
    if ~isempty(event)
        % Add latencies to event markers and adjust their time
        % stamps so that time 0 is the first data sample from the
        % eye data.
        timestamps = eyeDataStruct.time_stamps;
        latencies = nan(size(eventtimes));
        for ii = 1:numel(latencies)
            [~, latencies(ii)] = min(abs(timestamps - eventtimes(ii)));
        end
        eventtimes = eventtimes - eyeDataStruct.time_stamps(1);
        event = struct(...
            'type', eventtypes(:)',...
            'time', num2cell(eventtimes(:)'),...
            'latency', num2cell(latencies(:)'),...
            'rt', repmat({nan}, size(latencies(:)')));
    end
    EYE = struct(...
        'urdiam', diam,...
        'urgaze', gaze,...
        'srate', srate);
end

EYE.event = event;

end