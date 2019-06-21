function outStructArray = pupl_xdfimport(varargin)

% Imports eye data or event logs from xdf
%
%   Inputs
% filename--char or cell array of char
% directory--char
% as--'eye data' (default) or 'event logs'
%   Outputs
% outStructArray--struct array

outStructArray = struct([]);

p = inputParser;
addParameter(p, 'filename', [])
addParameter(p, 'directory', '.')
parse(p, varargin{:});

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

idx = []; idxSelected = false;

for fileIdx = 1:numel(filename)
    [~, name] = fileparts(filename{fileIdx});
    currStruct = struct(...
        'name', name,...
        'src', sprintf('%s\\%s', directory, filename{fileIdx}));
    fprintf('Loading %s...\n', filename{fileIdx});
    streams = load_xdf([directory '\\' filename{fileIdx}]);
    streamTypes = cellfun(@(x) x.info.type, streams, 'un', 0);
    if ~exist('eyeDataStreamType', 'var')
        persistent eyeDataStreamType;
        eyeDataStreamType = streamTypes(listdlg(...
            'PromptString', 'Which stream contains the eye data?',...
            'ListString', streamTypes,...
            'SelectionMode', 'single',...
            'ListSize', listSize));
        if isempty(eyeDataStreamType)
            outStructArray = struct([]);
            return
        end
    end
    if ~exist('eventsStreamType', 'var')
        persistent eventsStreamType;
        eventsStreamTypeOpts = [streamTypes 'none of the above'];
        eventsStreamType = eventsStreamTypeOpts(listdlg(...
            'PromptString', 'Which stream contains the event markers?',...
            'ListString', eventsStreamTypeOpts,...
            'SelectionMode', 'single',...
            'ListSize', listSize));
        if isempty(eventsStreamType)
            outStructArray = struct([]);
            return
        end
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
            fprintf('\t%d events found\n', numel(events));
            event = struct(...
                'type', events,...
                'time', num2cell(times));
        end
    else
        event = [];
    end
    
    eyeDataStruct = streams{strcmpi(streamTypes, eyeDataStreamType)};
    fprintf('\tNominal sample rate: %s Hz\n', eyeDataStruct.info.nominal_srate);
    srate = eyeDataStruct.info.effective_srate;
    fprintf('\tEffective sample rate: %f Hz\n', srate);
    if isempty(eyeDataStruct)
        fprintf('No eye data in %s\n', filename{fileIdx});
    else
        srate = str2double(eyeDataStruct.info.nominal_srate);
        fprintf('\tReplacing 0s with NaNs\n')
        eyeDataStruct.time_series(eyeDataStruct.time_series == 0) = NaN;
        fprintf('\tFound %s channels\n', eyeDataStruct.info.channel_count)
        channelNames = cellfun(@(x) lower(x.label), eyeDataStruct.info.desc.channels.channel, 'un', 0);
        data = [];
        for currField1 = {'diameter' 'gaze'}
            for currField2 = {'left' 'right'}
                for currField3 = {'x' 'y'}
                    if ~idxSelected
                        currIdx = listdlg(...
                            'PromptString', sprintf('Which channel is %s %s %s?', currField2{:}, currField3{:}, currField1{:}),...
                            'ListString', channelNames,...
                            'SelectionMode', 'single',...
                            'ListSize', listSize);
                        if isempty(currIdx)
                            outStructArray = struct([]);
                            return;
                        else
                            idx.(currField1{:}).(currField2{:}).(currField3{:}) = currIdx; 
                        end
                    end
                    fprintf('\tTreating channel %s as %s %s %s\n',...
                        channelNames{idx.(currField1{:}).(currField2{:}).(currField3{:})},...
                        currField2{:},...
                        currField1{:},...
                        currField3{:});
                    if strcmpi(currField1{:}, 'diameter')
                        data.(currField1{:}).(currField2{:}).(currField3{:}) =...
                            double(eyeDataStruct.time_series(idx.(currField1{:}).(currField2{:}).(currField3{:}), :));
                    elseif strcmpi(currField1{:}, 'gaze')
                        data.(currField1{:}).(currField3{:}).(currField2{:}) =...
                            double(eyeDataStruct.time_series(idx.(currField1{:}).(currField2{:}).(currField3{:}), :));
                    end
                end
            end
        end
        idxSelected = true;
        if ~isempty(event)
            % Add latencies to event markers and adjust their time
            % stamps so that time 0 is the first data sample from the
            % eye data.
            times = [event.time] - eyeDataStruct.time_stamps(1);
            [~, latencies] = min(abs(bsxfun(@minus,...
                reshape(eyeDataStruct.time_stamps,...
                    [], 1),...
                reshape([event.time],...
                    1, []))));
            % latencies = round(times*srate + 1);
            times = num2cell(times);
            latencies = num2cell(latencies);
            [event.time] = times{:};
            [event.latency] = latencies{:};
        end
        currStruct.diam = data.diameter;
        currStruct.urDiam = data.diameter;
        currStruct.srate = srate;
        currStruct.gaze = data.gaze;
        currStruct.urGaze = data.gaze;
    end
    currStruct.event = event;
    fprintf('\tMerging left and right gaze streams\n')
    currStruct = mergedata(currStruct, 'gazelr');
    fprintf('\tMerging x and y diameter measurements\n')
    currStruct = mergedata(currStruct, 'diamxy');
    outStructArray = cat(2, outStructArray, currStruct);
end
outStructArray = pupl_check(outStructArray);

fprintf('Done\n');

end