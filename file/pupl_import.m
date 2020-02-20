
function EYE = pupl_import(varargin)

% Handles importing of all data

global pupl_globals

args = pupl_args2struct(varargin, {
    'eyedata' struct([]) % optional, only required if adding event logs
    'loadfunc' []; % required
    'filepath' []; % optional
    'filefilt' '*.*' % optional
    'type' 'eye' % 'eye', 'event', or 'both'--required
    'bids' false % use BIDS?
    'args' {} % cell array of extra args passed to loadfunc
    'native' false % load data from pupl's built-in format?
});

type_opts = {'eye' 'event'};
args.type = find(strcmp(args.type, type_opts));

if args.native
    switch args.type
        case 1
            args.filefilt = ['*.' pupl_globals.ext];
        case 2
            args.filefilt = '*.tsv';
    end
end

EYE = args.eyedata;

if isempty(args.filepath) % Get path
    if args.bids
        datapath = uigetdir(pwd, 'Select data folder (e.g. sourcedata/ or raw/)');
        if isnumeric(datapath)
            return
        end
        switch args.type
            case {1 3}
                fmt = '_eyetrack.';
            case 2
                fmt = '_events.';
        end
        parsed = pupl_BIDS_parse(datapath, fmt);
        args.filepath = {parsed.full};
    else
        switch args.type
            case 1
                [filenames, directory] = uigetfile(args.filefilt,...
                    'MultiSelect', 'on');
                if isnumeric(filenames)
                    return
                end
                args.filepath = strcat(directory, cellstr(filenames));
            case 2
                args.filepath = cell(1, numel(EYE));
                directory = '';
                for dataidx = 1:numel(EYE)
                    [filename, directory] = uigetfile([directory '*.*'],...
                        sprintf('Event log for %s', EYE(dataidx).name),...
                        'MultiSelect', 'off');
                    if isnumeric(filename)
                        return
                    end
                    args.filepath{dataidx} = fullfile(directory, filename);
                end
        end
    end
end

if args.native && args.bids % Load eye data and event logs
    % First load the eye data
    EYE = pupl_import('filepath', args.filepath, 'native', true);
    BIDS = pupl_BIDS_parse(args.filepath, '_eyedata');
    [EYE.BIDS] = BIDS.info;
    % Get paths to respective event logs
    event_paths = cellfun(@fileparts, args.filepath, 'UniformOutput', false);
    event_files = cell(size(event_paths));
    for idx = 1:numel(event_paths)
        file = dir(fullfile(event_paths{idx}, '*.tsv'));
        if isempty(file)
            event_files{idx} = '';
        else
            event_files{idx} = fullfile(file.folder, file.name);
        end
    end
    EYE = pupl_import('eyedata', EYE, 'filepath', event_files, 'native', true, 'type', type_opts{2});
else
    args.filepath = cellstr(args.filepath);
    for dataidx = 1:numel(args.filepath)
        if isempty(args.filepath{dataidx})
            continue
        end
        [~, fname] = fileparts(args.filepath{dataidx});
        fprintf('Loading %s...', fname);
        
        % Load data
        if args.native
            switch args.type
                case 1
                    curr = pupl_load(args.filepath{dataidx});
                case 2
                    curr = tsv2eventlog(args.filepath{dataidx});
            end
        else
            curr = pupl_checkraw(...
                args.loadfunc(args.filepath{dataidx}, args.args{:}),...
                'src', args.filepath{dataidx},...
                'type', type_opts{args.type});
            curr.getraw = sprintf('@() pupl_import(''type'', %s, ''loadfunc'', %s, ''filepath'', %s, ''args'', %s)',... % Brings us back here next time
                all2str(type_opts{args.type}),...
                all2str(args.loadfunc),...
                all2str(args.filepath{dataidx}),...
                all2str(args.args));
        end
        
        % Concatenate eye data to output or attach event log to eye data
        switch args.type
            case 1
                try
                    BIDS = pupl_BIDS_parse(curr.src);
                    if ~isempty(BIDS)
                        curr.BIDS = BIDS.info;
                    end
                end
                [EYE, curr] = fieldconsistency(EYE, curr);
                EYE = cat(pupl_globals.catdim, EYE, curr);
            case 2
                if args.bids % Match automatically
                    matchidx = strcmp(...
                        stripmod(args.filepath{dataidx}),...
                        cellfun(@stripmod, {EYE.src}, 'UniformOutput', false));
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

EYE = pupl_check(EYE);

end

function s = stripmod(s)

% Strip modality (_eyetrack or _event)

[~, s] = fileparts(s);
s(find(s == '_', 1, 'last'):end) = [];

end