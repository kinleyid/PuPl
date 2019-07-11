
function eventLogsArray = loadnoldusexcel(varargin)

% Input: full path to file

eventLogsArray = [];

if nargin ~= 1
    [filename, directory] = uigetfile('*.*',...
        'MultiSelect', 'off');
    if isnumeric(filename)
        return
    end
else
    [directory, name, ext] = fileparts(varargin{1});
    filename = sprintf('%s', name, ext);
end
filename = cellstr(filename);

for fileIdx = 1
    % fprintf('Importing %s...\n', filename{fileIdx});
    [~, ~, R] = xlsread([directory '\\' filename{fileIdx}]);
    eventTypes = R(2:end, strcmp(R(1, :), 'Behavior'));
    modifiers = find(~cellfun(@isempty, (regexp(R(1, :), 'Modifier*'))));
    for modifierIdx = modifiers
        eventTypes = strcat(eventTypes, R(2:end, modifierIdx));
    end
    if any(strcmp(R(1, :), 'Event_Type'))
        eventTypes = strcat(eventTypes, R(2:end, strcmp(R(1, :), 'Event_Type')));
    end
    eventTimes = cell2mat(R(2:end, strcmp(R(1,:), 'Time_Relative_sf'))); % Time is in seconds
    
    eventLogsArray = [
        eventLogsArray
        struct(...
            'name', filename{fileIdx},...
            'src', sprintf('%s/%s', directory, filename{fileIdx}),...
            'event',...
                struct('time', num2cell(eventTimes),...
                       'type', eventTypes,...
                       'rt', repmat({NaN}, size(eventTimes))));
    ];
end

end