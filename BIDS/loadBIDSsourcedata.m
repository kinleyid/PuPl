
function out = loadBIDSsourcedata(varargin)

out = struct([]);

if nargin > 0
    sourcedatapath = varargin{1};
else
    sourcedatapath = uigetdir(pwd, 'Select sourcedata folder');
    if isnumeric(sourcedatapath)
        return
    end
end

parsed = parseBIDS(sourcedatapath);

fprintf('Loading from %s...\n', sourcedatapath);
for dataidx = 1:numel(parsed)
    % Find eye data
    [~, n, x] = fileparts(parsed(dataidx).full);
    fprintf('\tLoading %s...', [n x]);
    currdata = loadeyedata(parsed(dataidx).full);
    currdata.BIDS = parsed(dataidx).info;
    fprintf('done\n');
    % Check for event log
    contents = dir(parsed(dataidx).path);
    eventlogidx = strcmp({contents.name}, [stripmod(parsed(dataidx).full) '_events.tsv']);
    if any(eventlogidx)
        fprintf('\t\tLoading event log: %s...', contents(eventlogidx).name);
        currdata.eventlog = tsv2eventlog(fullfile(parsed(dataidx).path, contents(eventlogidx).name));
        fprintf('done\n');
    end
    out = [out currdata];
end
fprintf('Done\n');

end