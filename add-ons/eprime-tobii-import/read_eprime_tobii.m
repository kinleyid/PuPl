
% Based on
% https://pstnet.com/wp-content/uploads/2019/05/EET_User_Guide_3.2.pdf
% Task 7, pp 57-59

function EYE = read_eprime_tobii(fullpath)

EYE = [];

r = readdelim2cell(fullpath, '\t');
cols = r(1, :);
content = r(2:end, :);

% Get pupil diameter and gaze data
for side = {'Left' 'Right'}
    diam_data = content(:, strcmp(cols, sprintf('PupilDiameter%sEye', side{:})));
    EYE = setfield(EYE, 'pupil', lower(side{:}), str2double(diam_data));
    for ax = {'X' 'Y'}
        gaze_data = content(:, strcmp(cols, sprintf('GazePointPositionDisplay%s%sEye', ax{:}, side{:})));
        EYE = setfield(EYE, 'gaze', lower(ax{:}), lower(side{:}), str2double(gaze_data));
    end
end

% Record units
EYE.units = [];
EYE.units.pupil = {'diameter' 'mm' 'absolute'};
EYE.units.gaze = [];
EYE.units.gaze.x = {'x' 'proportion of screen' 'from screen left'};
EYE.units.gaze.y = {'y' 'proportion of screen' 'from screen top'};

% Get timestamps and srate
timestamps = str2double(content(:, strcmp(cols, 'RTTimeMicro')));
timestamps_s = timestamps/1000/1000; % From microseconds to seconds
t1 = timestamps_s(1);
timestamps_s = timestamps_s - t1; % Set first timestamp to 0
EYE.times = timestamps_s;
EYE.srate = estimatesrate(timestamps_s);

% Parse built-in events
% A new built-in event occurs for each conjunction of CurrentObject and
% ComponentName
gaze_event_cols = {'CurrentObject' 'ComponentName'};
gaze_event_data = content(:, ismember(cols, gaze_event_cols));
gaze_event_data = mat2cell(gaze_event_data, ones(size(gaze_event_data, 1), 1), 2);
gaze_event_types = cellfun(@(x) strcat(x{:}), gaze_event_data, 'UniformOutput', false);
unique_gaze_event_types = unique(gaze_event_types);
EYE.event = [];
for gaze_event_type = unique_gaze_event_types(:)'
    if isempty(gaze_event_type{:})
        continue
    end
    event_onsets = find(diff([false; strcmp(gaze_event_type, gaze_event_types)]) > 0);
    for onset = event_onsets(:)'
        curr_event = struct(...
            'name', 'gaze event',...
            'time', timestamps_s(onset));
        for evar_col = gaze_event_cols
            curr_event.(evar_col{:}) = content{onset, strcmp(cols, evar_col)};
        end
        curr_event.('CurrentFixationDuration') = str2double(content{onset, strcmp(cols, 'CurrentFixationDuration')});
        EYE.event = [EYE.event curr_event];
    end
end

% Parse user-defined events
user_defined_cols = 56:numel(cols);
event_data = content(:, user_defined_cols);
% There is a great deal of redundancy in the event records: the current
% value of each variable is recorded for each eye data sample. I'm assuming
% that the 
event_data = mat2cell(event_data, ones(size(event_data, 1), 1), numel(user_defined_cols));
event_types = cellfun(@(x) strcat(x{:}), event_data, 'UniformOutput', false);
unique_event_types = unique(event_types);
for event_type = unique_event_types(:)'
    event_onsets = find(diff([false; strcmp(event_type, event_types)]) > 0);
    for onset = event_onsets(:)'
        curr_event = struct(...
            'name', 'user-defined event',...
            'time', timestamps_s(onset));
        for evar_col = user_defined_cols
            curr_event.(cols{evar_col}) = content{onset, evar_col};
        end
        [EYE.event, curr_event] = fieldconsistency(EYE.event, curr_event);
        EYE.event = [EYE.event curr_event];
    end
end

end