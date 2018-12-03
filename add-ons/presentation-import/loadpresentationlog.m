function eventLogsArray = loadpresentationlog(varargin)

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
    fprintf('Importing %s...', filename{fileIdx})
    [~, name] = fileparts(filename{fileIdx});
    fID = fopen([directory '\\' filename{fileIdx}]);
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
    eventLogsArray = [
        eventLogsArray...
        struct('name', name,...
            'event', struct('time', num2cell(eventTimes),...
                            'type', eventTypes))];
    fprintf('done\n')
end