
function EYE = pupl_importraw(varargin)

p = inputParser;
addParameter(p, 'eyedata', struct([])); % optional
addParameter(p, 'loadfunc', []); % required
addParameter(p, 'fullpath', []); % optional
addParameter(p, 'type', []); % eye or event, required
parse(p, varargin{:});

EYE = p.Results.eyedata;

if isempty(p.Results.fullpath) % Get path
    q = 'Load BIDS raw data?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
    switch a
        case 'Yes'
            usebids = true;
        case 'No'
            usebids = false;
        otherwise
            return
    end
    if usebids
        rawdatapath = uigetdir(pwd, 'Select project folder');
        if isnumeric(rawdatapath)
            return
        end
        switch p.Results.type
            case 'eye'
                fmt = '_eyetrack.';
            case 'event'
                fmt = '_events.';
        end
        contents = dir(rawdatapath);
        rawidx = strcmp({contents.name}, 'raw');
        if any(rawidx)
            rawdatapath = fullfile(rawdatapath, contents(rawidx).name);
        end
        parsed = parseBIDS(rawdatapath, fmt);
        fullpath = {parsed.full};
    else
        switch p.Results.type
            case 'eye'
                [filenames, directory] = uigetfile('*.*',...
                    'MultiSelect', 'on');
                if isnumeric(filenames)
                    return
                end
                fullpath = strcat(directory, cellstr(filenames));
            case 'event'
                fullpath = {};
                directory = '';
                for dataidx = 1:numel(EYE)
                    [filename, directory] = uigetfile([directory '*.*'],...
                        sprintf('Event log for %s', EYE(dataidx).name),...
                        'MultiSelect', 'off');
                    if isnumeric(filename)
                        return
                    end
                    fullpath = [fullpath fullfile(directory, filename)];
                end
        end
    end
else
    fullpath = p.Results.fullpath;
end

for dataidx = 1:numel(fullpath)
    fprintf('Loading %s...', fullpath{dataidx});
    curr = rawloader(p.Results.loadfunc, fullpath{dataidx}); % Get bare data
    switch p.Results.type
        case 'eye'
            curr.getraw = str2func(sprintf('@()pupl_check(rawloader(@%s, ''%s''))', func2str(p.Results.loadfunc), curr.src));
            if usebids
                [~, filehead] = fileparts(curr.src);
                curr.BIDS = parseBIDSfilename(filehead);
            end
            EYE = [EYE pupl_check(curr)];
        case 'event'
            if usebids
                matchidx = strcmp(...
                    stripmod(fullpath{dataidx}),...
                    cellfun(@stripmod, {EYE.src}, 'un', 0));
                if any(matchidx)
                    EYE(matchidx).eventlog = curr;
                end
            else
                EYE(dataidx).eventlog = curr;
            end
    end
    fprintf('done\n');
end

end