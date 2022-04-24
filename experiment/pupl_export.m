
function pupl_export_2(EYE, varargin)
% Export data to a CSV spreadsheet
%
% Inputs
%   which: string ('stats' or 'data')
%   trialwise: 'epochs' or 'sets'; controls the unit of analysis
%   cfg: structure controlling the export (differs based on whether stats
%      or data are being exported)
%   path: name of output file

%% Get missing args

args = pupl_args2struct(varargin, {
    'which' []
    'trialwise' []
    'cfg' []
    'path' []
});

stat_opts = [
%   {Name presented to user} {function} {column name in spreadsheet} {type of data used for computation (if empty, defaults to {'pupil' 'both'})}
    {'Mean'} {@(x)nanmean_bc(x)} {'mean'} {[]};...
    {'Peak-to-peak difference'} {@(x)(max(x) - min(x))} {'peak_to_peak_diff'} {[]};...
    {'Max'} {@(x)max(x)} {'max'} {[]};...
    {'Min'} {@(x)min(x)} {'min'} {[]};...
    {'Median'} {@(x)nanmedian_bc(x)} {'median'} {[]};...
    {'Peak latency'} {@(x,e)peaklat(x,e.srate)} {'peak_lat'} {[]}
    {'Dip latency'} {@(x,e)diplat(x,e.srate)} {'dip_lat'} {[]}
    {'Standard deviation'} {@(x)nanstd_bc(x)} {'stdev'} {[]};...
    {'Variance'} {@(x)nanvar_bc(x)} {'variance'} {[]};...
    {'Percent missing'} {@(x)100*nnz(isnan(x))/numel(x)} {'pct_missing'} {[]}
    {'Median absolute deviation'} {@(x)nanmedian_bc(abs(x-nanmean_bc(x)))} {'mad'} {[]}
    {'Number of blinks'} {@(x)nnz(diff(x=='b')==1)} {'n_blinks'} {{'datalabel'}}
    {'Number of saccades'} {@(x)nnz(diff(x(1:end-1)=='s')==1)} {'n_sacc'} {{'interstices'}}
];

% Store names as variables in case I decide to change them
per_epoch = 'per-epoch';
set_avg = 'set-avg';

if isempty(args.which)
    q = 'What do you want to export?';
    a = questdlg(q, q, 'Statistics', 'Epoch data', 'Cancel', 'Statistics');
    switch a
        case 'Epoch data'
            args.which = 'data';
        case 'Statistics'
            args.which = 'stats';
        otherwise
            return
    end
end

if isempty(args.cfg)
    switch args.which
        case 'stats'
            args.cfg = struct(...
                'stats', [],...
                'sub_epoch_windows', []);
        case 'data'
            args.cfg = struct(...
                'long_or_wide', []);
    end
end

if strcmp(args.which, 'stats')
    if isempty(args.cfg.stats)
        sel = listdlgregexp('PromptString', sprintf('Compute which statistics?'),...
            'ListString', stat_opts(:, 1),...
            'regexp', false);
        if isempty(sel)
            return
        else
            args.cfg.stats = reshape(stat_opts(sel, 3), 1, []);
        end
    end
end

if isempty(args.trialwise)
    trialwise_opts = {
        'Individual epochs'
        'Epoch set averages'
    };
    switch args.which
        case 'data'
            q = 'Export individual epochs or epoch set averages?';
        case 'stats'
            q = 'Compute statistics on individual epochs or epoch set averages?';
    end
    sel = questdlg(q, q, trialwise_opts{:}, 'Cancel', trialwise_opts{1});
    switch sel
        case trialwise_opts
            switch sel
                case 'Individual epochs'
                    args.trialwise = per_epoch;
                case 'Epoch set averages'
                    args.trialwise = set_avg;
            end
        otherwise
            return
    end
end

% Set the remaining configuration settings (sub-windows for stats,
% long-vs-wide format for data)
switch args.which
    case 'stats'
        if isempty(args.cfg.sub_epoch_windows)
            q = 'Compute statistics on sub-epoch windows?';
            a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
            switch a
                case 'Yes'
                    while true
                        switch args.trialwise
                            case per_epoch
                                win_description = 'epoch';
                            case set_avg
                                win_description = 'epoch set average';
                        end
                        win = inputdlg({
                            sprintf('Define sub-epoch window centred on epoch timelocking events (if left empty, the window start and end default to the beginning and end of the %s, respectively)\n\nWindow start:', win_description)
                            'Window end:'
                        });
                        if isempty(win)
                            return
                        else
                            if isempty(win{1})
                                win{1} = [];
                            end
                            if isempty(win{2})
                                win{2} = [];
                            end
                            str_win = win;
                            if isempty(str_win{1})
                                switch args.trialwise
                                    case per_epoch
                                        str_win{1} = 'beginning of epoch';
                                    case set_avg
                                        str_win{1} = 'beginning of epoch set average';
                                end
                            end
                            if isempty(win{2})
                                switch args.trialwise
                                    case per_epoch
                                        str_win{2} = 'end of epoch';
                                    case set_avg
                                        str_win{2} = 'end of epoch set average';
                                end
                            end
                        end
                        name = (inputdlg(...
                            {sprintf('Name of sub-epoch window from %s to %s', str_win{:})}));
                        if isempty(name)
                            return
                        else
                            name = name{:};
                        end
                        args.cfg.sub_epoch_windows = [
                            args.cfg.sub_epoch_windows...
                            struct(...
                                'name', name,...
                                'lims', {win})
                        ];
                        q = 'Compute statistics in another sub-epoch window?';
                        a = questdlg(q);
                        switch a
                            case 'Yes'
                                continue
                            case 'No'
                                break
                            otherwise
                                return
                        end
                    end
                case 'No'
                    args.cfg.sub_epoch_windows = struct(...
                        'name', '',...
                        'lims', {{[] []}});
                otherwise
                    return
            end
        end
    case 'data'
        if isempty(args.cfg.long_or_wide)
            q = 'Long or wide format?';
            a = questdlg(q, q, 'Long', 'Wide', 'Cancel', 'Long');
            switch a
                case {'Long' 'Wide'}
                    args.cfg.long_or_wide = lower(a);
                otherwise
                    return
            end
        end
end

% If wide format, ensure consistent sample rates
if strcmp(args.which, 'data')
    if strcmp(args.cfg.long_or_wide, 'wide')
        if numel(EYE) > 1
            if ~isequal(EYE.srate)
                error_txt = {'Inconsistent sample rates:'};
                for ii = 1:numel(EYE)
                    error_txt{end + 1} = sprintf('\t%s: %f Hz', EYE(ii).name, EYE(ii).srate);
                end
                error_txt{end + 1} = 'Epoch data can be exported to wide format only when every recording has the same sample rate';
                error('%s\n', error_txt{:})
            end
        end
    end
end

if isempty(args.path)
    [f, d] = uiputfile('*.csv');
    if isnumeric(f)
        return
    end
    args.path = fullfile(d, f);
end

if strcmp(args.which, 'stats')
    if numel(unique({args.cfg.sub_epoch_windows.name})) < numel(args.cfg.sub_epoch_windows)
        error('Sub-epoch windows must all have unique names');
    end
end

%% Main function

% First, create cell arrays containing the non-data-related column names
cond_colnames = unique(mergefields(EYE, 'cond')); % Condition membership
set_colnames = unique(mergefields(EYE, 'epochset', 'name')); % Set membership
switch args.trialwise
    case per_epoch
        % There will be column names specific to each epoch
        epoch_colnames = {
            'timelocking_event'
            'timelocking_event_time'
            'epoch_idx'
            'epoch_name'
            'rejected'}';
        % There will be no column names specific to each epoch set
        epochset_colnames = [];
        % Each event variable will appear in its own column
        evar_colnames = pupl_evar_getnames(mergefields(EYE, 'event'));
        evar_colnames = evar_colnames(:)';
    otherwise
        % There will be column names specific to each epoch set
        epochset_colnames = {
            'epoch_set'
            'n_epochs'
        }';
        % There will be no epoch-specific column names
        epoch_colnames = [];
        % Figure out which event variables to compute mean and median on
        % (it will be the numeric event variables)
        all_evar_names = pupl_evar_getnames(mergefields(EYE, 'event'));
        evar_colnames = [];
        for curr_evar_name = all_evar_names
            curr_evar_contents = mergefields(EYE, 'event', curr_evar_name{:});
            if ~iscell(curr_evar_contents)
                % If not a cell, must be numeric
                evar_colnames = [evar_colnames curr_evar_name];
            end
        end
end

% Initialize a set of cell arrays that will contain information pertaining
% to each epoch or each epoch set

all_info = []; % This will be a struct array recording info about the epochs or epochsets

all_response_values = {}; % Response values---either the data itself (plus latencies) or statistics computed thereupon

fprintf('Compiling spreadsheet...\n');

switch args.trialwise
    case per_epoch
        fprintf('\tCollecting epochs');
    case set_avg
        fprintf('\tCollecting epoch set averages');
end
if strcmp(args.which, 'stats')
    fprintf(' and computing statistics'); 
end
fprintf('\n');

for dataidx = 1:numel(EYE)
    fprintf('\t\t%s\t', EYE(dataidx).name);
    EYE(dataidx) = pupl_mergelr(EYE(dataidx));
    switch args.trialwise
        case per_epoch
            %% Collect epochs and possibly compute statistics
            n_epochs = numel(EYE(dataidx).epoch);
            printprog('setmax', 10);
            last_pct = 0;
            for epochidx = 1:n_epochs
                % Print progress
                curr_pct = round(10 * epochidx / n_epochs);
                if curr_pct > last_pct
                    printprog(curr_pct);
                    last_pct = curr_pct;
                end
                % Get epoch info
                epoch_selector = [];
                epoch_selector.idx = epochidx;
                curr_epoch = pupl_epoch_get(EYE(dataidx), epoch_selector);
                curr_event = pupl_epoch_get(EYE(dataidx), epoch_selector, '_tl');
                curr_info = struct(...
                    'recording', EYE(dataidx).name,...
                    'timelocking_event', curr_event.name,...
                    'timelocking_event_time', curr_event.time,...
                    'epoch_idx', epochidx,...
                    'epoch_name', curr_epoch.name,...
                    'rejected', curr_epoch.reject);
                % Get event variabes
                if numel(evar_colnames) > 1
                    for evar_idx = 1:numel(evar_colnames)
                        curr_info.(evar_colnames{evar_idx}) = curr_event.(evar_colnames{evar_idx});
                    end
                end
                % Determine set membership
                % First set them all to false
                for epochset = set_colnames
                    curr_info.(sprintf('epoch_set_%s', epochset{:})) = false;
                end
                % Then determine which are true
                for setidx = 1:numel(EYE(dataidx).epochset)
                    currmembers = find(pupl_epoch_sel(...
                        EYE(dataidx), EYE(dataidx).epochset(setidx).members));
                    if ismember(epochidx, currmembers)
                        curr_info.(sprintf('epoch_set_%s', EYE(dataidx).epochset(setidx).name)) = true;
                    end
                end
                % Determine condition membership of the current recording
                % First set them all to false
                for cond = cond_colnames
                    curr_info.(sprintf('recording_cond_%s', cond{:})) = false;
                end
                for cond = EYE(dataidx).cond
                    curr_info.(sprintf('recording_cond_%s', cond{:})) = true;
                end
                % Get the "response values"---the actual epoch data or the
                % statistics computed on these
                switch args.which
                    case 'data'
                        [curr_epoch_data, ~, ~, ~, rel_lats] = pupl_epoch_getdata(...
                            EYE(dataidx),...
                            epoch_selector,...
                            'pupil', 'both');
                        % We can safely un-cell the data because we
                        % know we're only getting one epoch at a time
                        curr_epoch_data = curr_epoch_data{:};
                        rel_lats = rel_lats{:};
                        curr_response_values = struct(...
                            'data', curr_epoch_data,...
                            'rel_lats', rel_lats);
                    case 'stats'
                        n_stats = numel(args.cfg.stats);
                        n_windows = numel(args.cfg.sub_epoch_windows);
                        curr_response_values = [];
                        for statidx = 1:n_stats
                            curr_stat_name = args.cfg.stats{statidx};
                            % Find the information in the stat_opts array
                            % pertaining to the current stat
                            statoptidx = strcmp(curr_stat_name, stat_opts(:, 3));
                            % Get whatever data is needed to compute the
                            % current statistic
                            data_type = stat_opts{statoptidx, 4};
                            if isempty(data_type)
                                data_type = {'pupil' 'both'};
                            end
                            [curr_epoch_data, ~, ~, ~, rel_lats] = pupl_epoch_getdata(...
                                EYE(dataidx),...
                                epoch_selector,...
                                data_type{:});
                            % We can safely un-cell the data because we
                            % know we're only getting one epoch at a time
                            curr_epoch_data = curr_epoch_data{:};
                            rel_lats = rel_lats{:};
                            % Compute the current statistic on the
                            % requested sub-epoch windows
                            for winidx = 1:n_windows
                                % Get the indices of the current sub-epoch
                                % window
                                sub_win = get_sub_epoch_window(rel_lats, args.cfg.sub_epoch_windows(winidx).lims, EYE(dataidx).srate);
                                % Get the data of the current sub-epoch
                                % window
                                curr_win_data = curr_epoch_data(sub_win);
                                % Get the function to compute the current
                                % statistic
                                curr_func = str2func(func2str(stat_opts{statoptidx, 2}));
                                other_args = {};
                                if nargin(curr_func) == 2
                                    % data structure also provided as input
                                    other_args = {EYE(dataidx)};
                                end
                                curr_stat_value = feval(curr_func, curr_win_data, other_args{:});
                                curr_response_values = [curr_response_values...
                                    struct(...
                                        'stat', curr_stat_name,...
                                        'value', curr_stat_value,...
                                        'sub_epoch_window', args.cfg.sub_epoch_windows(winidx).name);
                                ];
                            end
                        end
                end
                all_response_values{end + 1} = curr_response_values;
                all_info = [all_info curr_info];
            end
        case set_avg
            %% Collect epoch set averages and possibly compute statistics
            n_sets = numel(EYE(dataidx).epochset);
            printprog('setmax', n_sets);
            for setidx = 1:n_sets
                curr_set = EYE(dataidx).epochset(setidx);
                epoch_selector = struct('set', curr_set.name);
                epochidx = pupl_epoch_sel(EYE(dataidx), epoch_selector);
                curr_info = struct(...
                    'recording', EYE(dataidx).name,...
                    'epoch_set', curr_set.name,...
                    'n_epochs', nnz(epochidx));
                % Compute mean and median of numeric event variables for
                % unrejected epochs
                if numel(evar_colnames) > 0
                    curr_epochs = pupl_epoch_get(EYE(dataidx), epoch_selector);
                    curr_events = pupl_epoch_get(EYE(dataidx), epoch_selector, '_ev');
                    curr_events = curr_events(~[curr_epochs.reject]);
                    for evar_idx = 1:numel(evar_colnames)
                        curr_evar_contents = [curr_events.(evar_colnames{evar_idx})];
                        if ~iscell(curr_evar_contents)
                            % Compute mean, then median
                            curr_info.(sprintf('evar_%s_mean', evar_colnames{evar_idx})) = nanmean_bc(curr_evar_contents);
                            curr_info.(sprintf('evar_%s_median', evar_colnames{evar_idx})) = nanmedian_bc(curr_evar_contents);
                        else
                            curr_info.(sprintf('evar_%s_mean', evar_colnames{evar_idx})) = nan;
                            curr_info.(sprintf('evar_%s_median', evar_colnames{evar_idx})) = nan;
                        end
                    end
                end
                                % Determine condition membership of the current recording
                % First set them all to false
                for cond = cond_colnames
                    curr_info.(sprintf('recording_cond_%s', cond{:})) = false;
                end
                for cond = EYE(dataidx).cond
                    curr_info.(sprintf('recording_cond_%s', cond{:})) = true;
                end
                % Compute percentage rejected
                [~, rej] = pupl_epoch_getdata(...
                    EYE(dataidx),...
                    epoch_selector,...
                    'pupil', 'both');
                curr_info.n_rejected = sum(rej);
                % Get the "response values"---the actual epoch data or the
                % statistics computed on these
                switch args.which
                    case 'data'
                        [curr_epoch_data, rej, ~, ~, rel_lats] = pupl_epoch_getdata(...
                            EYE(dataidx),...
                            epoch_selector,...
                            'pupil', 'both');
                        curr_epoch_data = cell2mat(curr_epoch_data);
                        curr_response_values = struct(...
                            'data', nanmean_bc(curr_epoch_data(~rej, :), 1),...
                            'rel_lats', rel_lats{1}); % We can safely take just the first one here---they'll all be the same
                    case 'stats'
                        n_stats = numel(args.cfg.stats);
                        n_windows = numel(args.cfg.sub_epoch_windows);
                        curr_response_values = [];
                        for statidx = 1:n_stats
                            curr_stat_name = args.cfg.stats{statidx};
                            % Find the information in the stat_opts array
                            % pertaining to the current stat
                            statoptidx = strcmp(curr_stat_name, stat_opts(:, 3));
                            % Get whatever data is needed to compute the
                            % current statistic
                            data_type = stat_opts{statoptidx, 4};
                            if isempty(data_type)
                                data_type = {'pupil' 'both'};
                            end
                            [curr_epoch_data, rej, ~, ~, rel_lats] = pupl_epoch_getdata(...
                                EYE(dataidx),...
                                epoch_selector,...
                                data_type{:});
                            % Based on the way pupl_epoch_getdata is
                            % written, we know that rel_lats will be a cell
                            % array whose elements are all the same---so we
                            % can safely just select the first one
                            rel_lats = rel_lats{1};
                            curr_epoch_data = cell2mat(curr_epoch_data);
                            curr_epoch_data = curr_epoch_data(~rej, :);
                            % Compute the current statistic on the
                            % requested sub-epoch windows
                            for winidx = 1:n_windows
                                % Get the indices of the current sub-epoch
                                % window
                                sub_win = get_sub_epoch_window(rel_lats, args.cfg.sub_epoch_windows(winidx).lims, EYE(dataidx).srate);
                                % Get the data of the current sub-epoch
                                % window
                                curr_win_data = curr_epoch_data(:, sub_win);
                                % Get the function to compute the current
                                % statistic
                                curr_func = str2func(func2str(stat_opts{statoptidx, 2}));
                                other_args = {};
                                if nargin(curr_func) == 2
                                    % data structure also provided as input
                                    other_args = {EYE(dataidx)};
                                end
                                % Should the statistic be computed on the
                                % epoch set mean, or should it be computed
                                % on each epoch and then averaged? E.g.,
                                % for n_blinks, it doesn't make sense to
                                % compute the epoch set mean first (and in
                                % fact, it's not possible because the data
                                % it's computed on is string rather than
                                % numeric)
                                if isnumeric(curr_win_data)
                                    curr_win_data = nanmean_bc(curr_win_data, 1);
                                    curr_stat_value = feval(curr_func, curr_win_data, other_args{:});
                                else
                                    n_epochs = size(curr_win_data, 1);
                                    epoch_wise_stat_vals = nan(1, n_epochs);
                                    for epochidx = 1:n_epochs
                                        epoch_wise_stat_vals(epochidx) = feval(curr_func, curr_win_data(epochidx, :), other_args{:});
                                    end
                                    curr_stat_value = nanmean_bc(epoch_wise_stat_vals);
                                end
                                curr_response_values = [curr_response_values...
                                    struct(...
                                        'stat', curr_stat_name,...
                                        'value', curr_stat_value,...
                                        'sub_epoch_window', args.cfg.sub_epoch_windows(winidx).name);
                                ];
                            end
                        end
                end
                all_response_values{end + 1} = curr_response_values;
                all_info = [all_info curr_info];
                printprog(setidx);
            end
    end
end
fprintf('\tFormatting data\t');
switch args.which
    case 'stats'
        data_colnames = [];
        data_content = [];
        n_stats = numel(args.cfg.stats);
        n_windows = numel(args.cfg.sub_epoch_windows);
        printprog('setmax', n_stats * n_windows);
        printprog_counter = 0;
        for statidx = 1:n_stats
            for winidx = 1:n_windows
                if isempty(args.cfg.sub_epoch_windows(winidx).name)
                    data_colname = args.cfg.stats{statidx};
                else
                    data_colname = [args.cfg.sub_epoch_windows(winidx).name '_' args.cfg.stats{statidx}];
                end
                data_colnames = [data_colnames {data_colname}];
                data_col = num2cell(nan(numel(all_response_values), 1));
                for rowidx = 1:numel(all_response_values)
                    stat_and_win = strcmp({all_response_values{rowidx}.stat}, args.cfg.stats(statidx)) & ...
                        strcmp({all_response_values{rowidx}.sub_epoch_window}, args.cfg.sub_epoch_windows(winidx).name);
                    data_col{rowidx} = all_response_values{rowidx}(stat_and_win).value;
                end
                data_content = [data_content data_col];
                printprog_counter = printprog_counter + 1;
                printprog(printprog_counter);
            end
        end
    case 'data'
        srate = EYE(1).srate; % Ensured earlier that sample rates were consistent
        switch args.cfg.long_or_wide
            case 'long'
                % Get column name for the data columns
                data_colnames = {'time'};
                epoch_units = mergefields(EYE, 'units', 'epoch');
                epoch_size = epoch_units(1:3:end);
                if isequal(epoch_size{:})
                    data_colnames = [data_colnames sprintf('pupil_%s', EYE(1).units.epoch{1})];
                else
                    data_colnames = [data_colnames 'pupil_size'];
                end
                % Get the content of the data column (times and pupil size)
                data_content = [];
                tmp_info = [];
                printprog('setmax', 10);
                last_pct = 0;
                n_row = numel(all_response_values);
                for rowidx = 1:n_row
                    % Print progress
                    curr_pct = round(10 * rowidx/ n_row);
                    if curr_pct > last_pct
                        printprog(curr_pct);
                        last_pct = curr_pct;
                    end
                    curr_resp_val = all_response_values{rowidx};
                    curr_rel_lats = unfold(curr_resp_val.rel_lats);
                    curr_rel_times = curr_rel_lats/srate;
                    data_content = [
                        data_content
                        [curr_rel_times(:) curr_resp_val.data(:)]
                    ];
                    % All of the other columns need to be duplicated for
                    % however many datapoints there are
                    tmp_info = [tmp_info repmat(all_info(rowidx), 1, numel(curr_rel_times))];
                end
                all_info = tmp_info;
                data_content = num2cell(data_content);
            case 'wide'
                % Figure out the min and max latency across all the data
                min_rel_lat = min(cellfun(@(x) min(x.rel_lats), all_response_values));
                max_rel_lat = max(cellfun(@(x) max(x.rel_lats), all_response_values));
                all_rel_lats = min_rel_lat:max_rel_lat;
                data_colnames = arrayfun(@(x) sprintf('t[%s]', num2str(x)), all_rel_lats/srate, 'UniformOutput', false);
                n_row = numel(all_response_values);
                data_content = nan(n_row, numel(all_rel_lats));
                printprog('setmax', 10);
                last_pct = 0;
                for rowidx = 1:n_row
                    % Print progress
                    curr_pct = round(10 * rowidx/ n_row);
                    if curr_pct > last_pct
                        printprog(curr_pct);
                        last_pct = curr_pct;
                    end
                    curr_rel_lats = all_response_values{rowidx}.rel_lats;
                    put_idx = curr_rel_lats(1) <= all_rel_lats & curr_rel_lats(2) >= all_rel_lats;
                    data_content(rowidx, put_idx) = all_response_values{rowidx}.data;
                end
                data_content = num2cell(data_content);
        end
end

fprintf('\tConverting to table\t');
% Convert all_info to a table (cell array)
nondata_colnames = reshape(fieldnames(all_info), 1, []);
n_col = numel(nondata_colnames);
n_row = numel(all_info);
printprog('setmax', 10);
last_pct = 0;
nondata_content = cell(n_row, n_col);
for rowidx = 1:n_row
    % Print progress
    curr_pct = round(10 * rowidx / n_row);
    if curr_pct > last_pct
        printprog(curr_pct);
        last_pct = curr_pct;
    end
    for colidx = 1:n_col
        curr_cell = all_info(rowidx).(nondata_colnames{colidx});
        if iscell(curr_cell)
            x = 10;
        end
        nondata_content{rowidx, colidx} = curr_cell;
    end
end
% Add column names
nondata_table = [
    nondata_colnames
    nondata_content
];

data_table = [
    data_colnames
    data_content
];

bigtable = [nondata_table data_table];

fprintf('Writing to %s...', args.path);
writecell2delim(args.path, bigtable, ',');
fprintf('Done\n');

if ~isempty(gcbf)
    global pupl_globals
    args_as_cell_array = pupl_struct2args(args);
    fprintf('\nEquivalent command:\n\n%s(%s, %s)\n\n', mfilename, pupl_globals.datavarname, all2str(args_as_cell_array{:}));
end

end

function sub_win = get_sub_epoch_window(rel_lats, str_win, srate)

% Default to beginning and end of current epoch if
% the corresponding sub-epoch window limit is empty
str_win(cellfun(@isempty, str_win)) = {nan};
curr_win = parsetimestr(str_win, srate, 'smp');
curr_win(isnan(curr_win)) = rel_lats(isnan(curr_win));
rel_lats = unfold(rel_lats);
sub_win = rel_lats >= curr_win(1) & rel_lats <= curr_win(2);

end