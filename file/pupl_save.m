function pupl_save(EYE, varargin)

% Save eye data or event logs
%   Inputs
% path
% batch

global pupl_globals

args = pupl_args2struct(varargin, {
    'path', []
    'as', [] % bin or txt
    'method', 'single' % 'single', 'batch', or 'bids'
    'data', 'both' % 'eye' or 'event' or 'both'
});

switch args.as
    case 'bin'
        if ismember(args.data, {'eye' 'both'})
            default_filenames = strcat({EYE.name}, sprintf('.%s', pupl_globals.ext));
        else
            default_filenames = strcat({EYE.name}, '.tsv');
        end
    case 'txt'
        if ismember(args.data, {'eye' 'both'})
            default_filenames = strcat({EYE.name}, '.txt');
        else
            default_filenames = strcat({EYE.name}, '.csv');
        end
        if isnonemptyfield(EYE, 'epoch') && ismember(args.data, {'eye' 'both'})
            q = 'PuPl''s text formats save only continuous data, events, and basic metadata (e.g., sample rate and units; not epochs). To avoid data loss, use the binary format. Continue?';
            a = questdlg(q, '', 'Yes', 'No', 'Yes');
            switch a
                case 'Yes'
                    % Continue
                otherwise
                    return
            end
        end
end

if isempty(args.path)
    switch args.method
        case 'single'
            args.path = {};
            for dataidx = 1:numel(EYE)
                [f, p] = uiputfile(default_filenames{dataidx},...
                    sprintf('Save %s', EYE(dataidx).name));
                if isnumeric(f)
                    if ~isempty(args.path)
                        q = 'Save the data you''ve already selected locations for?';
                        a = questdlg(q);
                        switch a
                            case 'Yes'
                                break
                            otherwise
                                return
                        end
                    else
                        return
                    end
                else
                    args.path{end + 1} = fullfile(p, f);
                end
            end
        case 'batch'
            args.path = uigetdir(pwd, 'Select a folder to put all the data in');
            if isnumeric(args.path)
                return
            end
        case 'bids'
            args.path = uigetdir(pwd, 'Select data folder (e.g. sourcedata/)');
            if isnumeric(args.path)
                return
            end         
    end
end

switch args.method
    case 'single'
        filepath = args.path;
    case 'batch'
        filepath = fullfile(args.path, default_filenames);
    case 'bids'
        filepath = {};
        for dataidx = 1:numel(EYE) % Populate
            masterfilehead = getfilehead(EYE(dataidx).BIDS);
            currfilehead = fullfile(args.path, masterfilehead);
            filepath{end + 1} = currfilehead;
        end
end

filepath = cellstr(filepath);

for dataidx = 1:numel(filepath)
    if strcmp(args.method, 'bids')
        curr_path = sprintf('%s_eyetrack', filepath{dataidx});
    else
        curr_path = filepath{dataidx};
    end
    % Make sure there's only one file extension
    [p, f] = fileparts(curr_path);
    % Save data
    switch args.as
        case 'bin'
            % Save continuous data
            if ismember(args.data, {'eye' 'both'})
                curr_path = fullfile(p, sprintf('%s.%s', f, pupl_globals.ext));
                fprintf('Saving %s...', curr_path);
                tmp = EYE(dataidx);
                save(curr_path, 'tmp', '-v6');
                fprintf('done\n');
            end
            % Save event data
            if ismember(args.data, {'event' 'both'})
                if strcmp(args.method, 'bids')
                    events_path = sprintf('%s_event.tsv', filepath{dataidx});
                else
                    events_path = fullfile(p, sprintf('%s.tsv', f));
                end
                fprintf('Saving %s...', events_path);
                eventlog2tsv(EYE(dataidx), events_path);
                fprintf('done\n');
            end
        case 'txt'
            % Save continuous data
            if ismember(args.data, {'eye' 'both'})
                curr_path = fullfile(p, sprintf('%s.txt', f));
                fprintf('Saving %s...', curr_path);
                pupl_txt(curr_path, 'w', 'c', EYE(dataidx));
                fprintf('done\n');
            end
            % Save event data
            if ismember(args.data, {'event' 'both'})
                if strcmp(args.method, 'bids')
                    events_path = sprintf('%s_event.csv', filepath{dataidx});
                else
                    events_path = fullfile(p, sprintf('%s.csv', f));
                end
                fprintf('Saving %s...', events_path);
                pupl_txt(events_path, 'w', 'e', EYE(dataidx));
                fprintf('done\n');
            end
    end
end

if ~isempty(gcbf)
    fprintf('\nEquivalent command:\n');
    cellargs = pupl_struct2args(args);
    fprintf('%s(%s, %s)\n\n', mfilename, pupl_globals.datavarname, all2str(cellargs{:}));
end

end

function filehead = getfilehead(BIDS)

currpath = sprintf('sub-%s/', BIDS.sub);
% Session-specific data?
if isfield(BIDS, 'ses')
    sespath = fullfile(currpath, sprintf('ses-%s', BIDS.ses));
    currpath = sespath;
end
currpath = fullfile(currpath, 'eyetrack');
filehead = fullfile(currpath, sprintf('sub-%s', BIDS.sub));
for field = {'ses' 'task' 'acq'  'run' 'recording' 'proc'}
    if isfield(BIDS, field{:})
        if ~isempty(BIDS.(field{:}))
            filehead = sprintf('%s_%s-%s', filehead, field{:}, BIDS.(field{:}));
        end
    end
end

end
