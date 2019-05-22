
function eventLogsArray = loadpresentationlog(varargin)

% Input: full path to file

eventLogsArray = [];

if nargin ~= 1
    [filename, directory] = uigetfile('*.*',...
        'MultiSelect', 'off');
    if isnumeric(filename)
        return
    end
else
    [directory, name, ext] = fileparts(file);
    filename = sprintf('%s', name, ext);
end
filename = cellstr(filename);

for fileIdx = 1 % God this is a lazy solution
    fprintf('Importing %s\n', filename{fileIdx})
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
        struct(...
            'name', name,...
            'loadsrc', sprintf('%s\\%s', directory, filename{fileIdx}),...
            'loadstr', sprintf('%s(''filename'', %s, ''directory'', %s)',...
                mfilename, filename{fileIdx}, directory),...
            'event', struct('time', num2cell(eventTimes),...
                            'type', eventTypes))];
    fprintf('\t%d events loaded\n', numel(eventTimes))
end

eventLogsArray = pupl_check(eventLogsArray);

end