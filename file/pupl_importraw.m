
function EYE = pupl_importraw(varargin)

p = inputParser;
addParameter(p, 'eyedata', struct([])); % optional
addParameter(p, 'loadfunc', []); % required
addParameter(p, 'fullpath', []); % optional
addParameter(p, 'filefilt', '*.*'); % optional
addParameter(p, 'type', 'eye'); % eye or event, required
addParameter(p, 'usebids', []); % use BIDS?
addParameter(p, 'args', {}); % cell array of extra args passed to loadfunc
parse(p, varargin{:});

EYE = p.Results.eyedata;

if isempty(p.Results.usebids)
    q = sprintf('Load BIDS raw data?\n(No to manually select individual files)');
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
    switch a
        case 'Yes'
            usebids = true;
        case 'No'
            usebids = false;
        otherwise
            return
    end
else
    usebids = p.Results.usebids;
end

if isempty(p.Results.fullpath) % Get path
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
                [filenames, directory] = uigetfile(p.Results.filefilt,...
                    'MultiSelect', 'on');
                if isnumeric(filenames)
                    return
                end
                fullpath = strcat(directory, cellstr(filenames));
            case 'event'
                fullpath = cell(1, numel(EYE));
                directory = '';
                for dataidx = 1:numel(EYE)
                    [filename, directory] = uigetfile([directory '*.*'],...
                        sprintf('Event log for %s', EYE(dataidx).name),...
                        'MultiSelect', 'off');
                    if isnumeric(filename)
                        return
                    end
                    fullpath{dataidx} = fullfile(directory, filename);
                end
        end
    end
else
    fullpath = p.Results.fullpath;
end

for dataidx = 1:numel(fullpath)
    [~, fname] = fileparts(fullpath{dataidx});
    fprintf('Loading %s...', fname);
    % Generate getraw function
    args = '';
    for ii = 1:numel(p.Results.args)
        args = sprintf('%s, %s', args, all2str(p.Results.args{ii}));
    end
    getraw = str2func(sprintf('@()loader(''%s'',''%s'',@%s,''%s''%s)',...
        'raw', p.Results.type, func2str(p.Results.loadfunc), fullpath{dataidx}, args));
    curr = feval(getraw);
    curr.getraw = getraw;
    switch p.Results.type
        case 'eye'
            if usebids
                [~, filehead] = fileparts(curr.src);
                curr.BIDS = parseBIDSfilename(filehead);
            end
            EYE = [EYE curr];
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
            EYE(dataidx) = pupl_check(EYE(dataidx));
    end
    fprintf('done\n');
end

end