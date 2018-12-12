function eventLogsArray = loadnoldusexcel(varargin)

eventLogsArray = [];

p = inputParser;
addParameter(p, 'filename', [])
addParameter(p, 'directory', '.');
parse(p, varargin{:});

directory = p.Results.directory;

if isempty(p.Results.filename)
    [filename, directory] = uigetfile([directory '\\*.*'],...
        'MultiSelect', 'on');
    if isnumeric(filename)
        return
    end
else
    filename = p.Results.filename;
end
filename = cellstr(filename);

for fileIdx = 1:numel(filename)
    fprintf('Importing %s...\n', filename{fileIdx});
    [~, ~, R] = xlsread([directory '\\' filename{fileIdx}]);
    eventTypes = R(2:end, strcmp(R(1, :), 'Behavior'));
    modifiers = find(~cellfun(@isempty, (regexp(R(1, :), 'Modifier*'))));
    for modifierIdx = modifiers
        eventTypes = strcat(eventTypes, R(2:end, modifierIdx));
    end
    eventTypes = strcat(eventTypes,R(2:end, strcmp(R(1, :), 'Event_Type')));
    eventTimes = cell2mat(R(2:end, strcmp(R(1,:), 'Time_Relative_sf'))); % Time is in seconds
    
    fprintf('\t%d events found\n', numel(eventTypes));
    
    eventLogsArray = [
        eventLogsArray...
        struct(...
            'name', filename{fileIdx},...
            'event',...
                struct('time', num2cell(eventTimes),...
                       'type', eventTypes))];
    fprintf('\tdone\n')
end

end