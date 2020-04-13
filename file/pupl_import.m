
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
num_type = find(strcmp(args.type, type_opts));

if args.native
    switch num_type
        case 1
            args.filefilt = ['*.' pupl_globals.ext];
        case 2
            args.filefilt = '*.tsv';
    end
end

EYE = args.eyedata;

if isempty(args.filepath) % Get path
    if args.bids
        args.filepath = uigetdir(pwd, 'Select data folder (e.g. sourcedata/ or raw/)');
        if isnumeric(args.filepath)
            EYE = 0;
            return
        end
    else
        switch num_type
            case 1
                [filenames, directory] = uigetfile(args.filefilt,...
                    'MultiSelect', 'on');
                if isnumeric(filenames)
                    EYE = 0;
                    return
                end
                args.filepath = strcat(directory, cellstr(filenames));
            case 2
                args.filepath = cell(1, numel(EYE));
                directory = '';
                for dataidx = 1:numel(EYE)
                    [filename, directory] = uigetfile([directory args.filefilt],...
                        sprintf('Event log for %s', EYE(dataidx).name),...
                        'MultiSelect', 'off');
                    if isnumeric(filename)
                        EYE = 0;
                        return
                    end
                    args.filepath{dataidx} = fullfile(directory, filename);
                end
        end
    end
end

if args.bids
    switch num_type
        case {1 3}
            fmt = '_eyetrack.';
        case 2
            fmt = '_events.';
    end
    parsed = pupl_BIDS_parse(args.filepath, fmt);
    filepath = {parsed.full};
else
    filepath = args.filepath;
end

if args.native && args.bids % Load eye data and event logs
    % First load the eye data
    EYE = pupl_import('filepath', filepath, 'native', true);
    BIDS = pupl_BIDS_parse(filepath, '_eyedata');
    [EYE.BIDS] = BIDS.info;
    % Get paths to respective event logs
    event_paths = cellfun(@fileparts, filepath, 'UniformOutput', false);
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
    filepath = cellstr(filepath);
    for dataidx = 1:numel(filepath)
        if isempty(filepath{dataidx})
            continue
        end
        [~, fname] = fileparts(filepath{dataidx});
        fprintf('Loading %s...', fname);
        
        % Load data
        if args.native
            switch num_type
                case 1
                    curr = pupl_load(filepath{dataidx});
                case 2
                    curr = tsv2eventlog(filepath{dataidx});
            end
        else
            data = args.loadfunc(filepath{dataidx}, args.args{:});
            if isempty(data)
                fprintf('\n');
                EYE = 0;
                return
            end
            curr = pupl_checkraw(...
                data,...
                'src', filepath{dataidx},...
                'type', args.type);
            curr.getraw = sprintf('@() pupl_import(''type'', %s, ''loadfunc'', %s, ''filepath'', %s, ''args'', %s)',... % Brings us back here next time
                all2str(args.type),...
                all2str(args.loadfunc),...
                all2str(filepath{dataidx}),...
                all2str(args.args));
        end
        
        % Concatenate eye data to output or attach event log to eye data
        switch num_type
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
                        stripmod(filepath{dataidx}),...
                        cellfun(@stripmod, {EYE.src}, 'UniformOutput', false));
                    if any(matchidx)
                        EYE(matchidx).eventlog = curr;
                    end
                else
                    fprintf('attaching to %s...', EYE(dataidx).name);
                    EYE(dataidx).eventlog = curr;
                end
                EYE(dataidx) = pupl_check(EYE(dataidx));
        end
        fprintf('done\n');
    end
    % Clear persistent variables
    if isa(args.loadfunc, 'function_handle')
        clear(func2str(args.loadfunc));
    end
end

stack = dbstack;
if ~isempty(gcbf) && ~strcmp(stack(2), mfilename)
    fprintf('\nEquivalent command:\n')
    if ~isempty(args.eyedata)
        eyedata = pupl_globals.datavarname;
    else
        eyedata = all2str(struct([]));
    end
    args = rmfield(args, 'eyedata');
    cellargs = pupl_struct2args(args);
    fprintf('%s = %s(''eyedata'', %s, %s)\n\n', pupl_globals.datavarname, mfilename, eyedata, all2str(cellargs{:}))
end

EYE = pupl_check(EYE);

end

function s = stripmod(s)

% Strip modality (_eyetrack or _event)

[~, s] = fileparts(s);
s(find(s == '_', 1, 'last'):end) = [];

end