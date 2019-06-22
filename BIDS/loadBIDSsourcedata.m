
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

for dataidx = 1:numel(parsed)
    % Find eye data
    currdata = loadeyedata(parsed(dataidx).full);
    currdata.BIDS = parsed(dataidx).info;
    % Check for event log
    contents = dir(parsed(dataidx).path);
    eventlogidx = strcmp({contents.name}, [parsed(dataidx).head '_events.tsv']);
    if any(eventlogidx)
        currdata.eventlog = tsv2eventlog(fullfile(currpath, contents(eventlogidx).name));
    end
    out = [out currdata];
end

end