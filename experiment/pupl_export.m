
function pupl_export(EYE, varargin)
% Export data to a CSV spreadsheet
%
% Inputs
%   which: string ('stats' or 'downsampled')
%   cfg:

%% Get missing args

args = pupl_args2struct(varargin, {
    'which' []
    'cfg' []
    'trialwise' []
    'path' []
    'lw' []
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
    {'Median absolute deviation'} {@(x)nanmedian_bc(x-nanmean_bc(x))} {'mad'} {[]}
    {'Number of blinks'} {@(x)nnz(diff(x=='b')==1)} {'n_blinks'} {{'datalabel'}}
    {'Number of saccades'} {@(x)nnz(diff(x(1:end-1)=='s')==1)} {'n_sacc'} {{'interstices'}}
];

% Store names as variables in case I decide to change them
per_epoch = 'Analyze individual epochs (e.g. for mixed effects models)';
set_avg = 'Analyze epoch set averages';
trialwise_opts = {
    per_epoch
    set_avg
};

if isempty(args.which)
    q = 'What do you want to export?';
    a = questdlg(q, q, 'Downsampled data', 'Statistics', 'Cancel', 'Statistics');
    switch a
        case 'Downsampled data'
            args.which = 'downsampled';
        case 'Statistics'
            args.which = 'stats';
        otherwise
            return
    end
end

if isempty(args.trialwise)
    sel = listdlgregexp('PromptString', 'How should individual trials be handled?',...
        'ListString', trialwise_opts,...
        'SelectionMode', 'single');
    if isempty(sel)
        return
    else
        args.trialwise = trialwise_opts{sel};
    end
end

if isempty(args.cfg)
    switch args.which
        case 'downsampled'
            fields = {
                % field | prompt | default
                'start' 'Start (relative to epoch-defining event; defaults to start of epoch)' ''
                'width' 'Width' '100ms'
                'step' 'Step size (defaults to width)' ''
                'end' 'End (relative to epoch-defining event; defaults to end of epoch)' ''
            };

            vals = inputdlg({sprintf('Define bins\n\n%s', fields{1, 2}), fields{2:end, 2}},...
                'Define bins', [1 50], fields(:, 3));
            if isempty(vals)
                return
            end
            for ii = 1:size(fields, 1)
                args.cfg.(fields{ii, 1}) = vals{ii};
            end
        case 'stats'
            while true
                win = inputdlg({
                    sprintf('Define statistics time window centred on epoch timelocking events (if left empty, the window start and end default to the beginning and end of the epoch, respectively)\n\nWindow start:')
                    'Window end:'
                });
                if isempty(win)
                    return
                else
                    if isempty(win{1})
                        win{1} = 'beginning of epoch';
                    end
                    if isempty(win{2})
                        win{2} = 'end of epoch';
                    end
                    str_win = win;
                end
                name = (inputdlg(...
                    {sprintf('Name of statistics time window from %s to %s', str_win{:})}));
                if isempty(name)
                    return
                else
                    name = name{:};
                end
                sel = listdlgregexp('PromptString', sprintf('Compute which statistics in window ''%s''?', name),...
                    'ListString', stat_opts(:, 1));
                if isempty(sel)
                    return
                else
                    stats = reshape(stat_opts(sel, 1), 1, []);
                    statsnames = reshape(stat_opts(sel, 3), 1, []);
                end
                args.cfg = [
                    args.cfg...
                    struct(...
                        'name', name,...
                        'win', {win},...
                        'stats', {stats},...
                        'statsnames', {statsnames})
                ];
                q = 'Compute more statistics in another time window?';
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
    end
end

if strcmp(args.which, 'downsampled')
    if isempty(args.lw)
        q = 'Long or wide format?';
        a = questdlg(q, q, 'Long', 'Wide', 'Cancel', 'Long');
        switch a
            case {'Long' 'Wide'}
                args.lw = lower(a);
            otherwise
                return
        end
    end
    
    % If wide format, ensure consistent sample rates
    if strcmp(args.lw, 'wide')
        if numel(EYE) > 1
            if ~isequal(EYE.srate)
                error_txt = {'Inconsistent sample rates:'};
                for ii = 1:numel(EYE)
                    error_txt{end + 1} = sprintf('\t%s: %f Hz', EYE(ii).name, EYE(ii).srate);
                end
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

%% Main function

info_colnames = {'recording'}; % Data columns will be added afterward
cond_colnames = unique(mergefields(EYE, 'cond')); % Condition membership
set_colnames = unique(mergefields(EYE, 'epochset', 'name')); % Set membership
switch args.trialwise
    case per_epoch
        trial_colnames = {
            'timelocking_event'
            'timelocking_time'
            'epoch_idx'
            'epoch_type'
            'rejected'}';
        evar_colnames = pupl_evar_getnames(mergefields(EYE, 'event'));
        evar_colnames = evar_colnames(:)';
    otherwise
        % Figure out which event variables to compute mean and median on
        all_evar_names = pupl_evar_getnames(mergefields(EYE, 'event'));
        evar_colnames = [];
        for curr_evar_name = all_evar_names
            curr_evar_contents = mergefields(EYE, 'event', curr_evar_name{:});
            if ~iscell(curr_evar_contents)
                % If not a cell, must be numeric
                evar_colnames = [evar_colnames curr_evar_name];
            end
        end
        trial_colnames = [];
end
all_info = {};
all_condmemberships = {};
all_setmemberships = {};
all_trialinfo = {};
all_evars = {};
all_data_rows = {};
all_epochsets = {};
% Only used for downsampling:
all_win_starts = {};
all_win_ends = {};
all_bef_aft = {};

% All data will be windowed. 
switch args.which
    case 'downsampled'
        win = {{args.cfg.start args.cfg.end}};
    case 'stats'
        win = {args.cfg.win};
end

fprintf('Getting data...\n');
rec_idx = {};
for dataidx = 1:numel(EYE)
    fprintf('\t%s...\n', EYE(dataidx).name);
    EYE(dataidx) = pupl_mergelr(EYE(dataidx));
    %% First, collect indices to windowed data in a cell array
    switch args.trialwise
        case per_epoch
            fprintf('Collecting indices to windowed data\t\t');
            collected_windows = cell(numel(EYE(dataidx).epoch), numel(win));
            collected_epochidx = cell(numel(EYE(dataidx).epoch), numel(win));
            n_epochs = numel(EYE(dataidx).epoch);
            printprog('setmax', 10);
            last_pct = 0;
            epoch_selector = [];
            for epochidx = 1:n_epochs
                % Print progress
                curr_pct = round(10 * epochidx / n_epochs);
                if curr_pct > last_pct
                    printprog(curr_pct);
                    last_pct = curr_pct;
                end
                % Get epoch info
                epoch_selector.idx = epochidx;
                all_info{end + 1} = EYE(dataidx).name;
                curr_epoch = pupl_epoch_get(EYE(dataidx), epoch_selector);
                curr_event = pupl_epoch_get(EYE(dataidx), epoch_selector, '_tl');
                all_trialinfo(end + 1, :) = {
                    sprintf('"%s"', curr_event.name)
                    curr_event.time
                    epochidx
                    curr_epoch.name
                    curr_epoch.reject
                };
                % Get trial vars
                curr_evars = {};
                for evar_idx = 1:numel(evar_colnames)
                    curr_evars{end + 1} = curr_event.(evar_colnames{evar_idx});
                end
                all_evars(end + 1, :) = curr_evars;
                % Determine set membership, lining up membership with column names
                curr_setnames = {EYE(dataidx).epochset.name};
                curr_setmembership = curr_setnames(...
                    arrayfun(...
                        @(desc) pupl_event_sel(...
                            curr_event,...
                            desc.members),...
                        [EYE(dataidx).epochset]));
                all_setmemberships{end + 1} = ismember(set_colnames, curr_setmembership);
                % Get indices to windowed data
                for winidx = 1:numel(win)
                    % Relative latencies of current epoch:
                    rel_lats = pupl_epoch_get(...
                        EYE(dataidx),...
                        epoch_selector,...
                        '_rel');
                    % Relative latencies of current statistics window:
                    str_win = win{winidx};
                    % Default to beginning and end of current epoch
                    str_win(ismember(str_win, {'beginning of epoch' 'end of epoch'})) = {nan};
                    curr_win = parsetimestr(str_win, EYE(dataidx).srate, 'smp');
                    curr_win(isnan(curr_win)) = rel_lats(isnan(curr_win));
                    rel_lats = unfold(rel_lats);
                    rel_win = rel_lats >= curr_win(1) & rel_lats <= curr_win(2);
                    collected_windows{epochidx, winidx} = rel_win;
                    % Keep track of which epoch this corrsponds to
                    collected_epochidx{epochidx, winidx} = epochidx;
                end
                rec_idx{end + 1} = dataidx;
            end
        case set_avg
            fprintf('Collecting windowed data\t\t\t\t');
            collected_windows = cell(numel(EYE(dataidx).epochset), numel(win));
            collected_epochidx = cell(numel(EYE(dataidx).epochset), numel(win));
            n_sets = numel(EYE(dataidx).epochset);
            printprog('setmax', n_sets);
            for setidx = 1:n_sets
                curr_set = EYE(dataidx).epochset(setidx);
                all_epochsets{end + 1} = curr_set.name;
                epoch_selector = struct('set', curr_set.name);
                epochidx = pupl_epoch_sel(EYE(dataidx), epoch_selector);
                % Get epoch info
                all_info{end + 1} = EYE(dataidx).name;
                % Compute mean and median of numeric event variables for
                % unrejected epochs
                curr_epochs = pupl_epoch_get(EYE(dataidx), epoch_selector);
                curr_events = pupl_epoch_get(EYE(dataidx), epoch_selector, '_ev');
                curr_events = curr_events(~[curr_epochs.reject]);
                curr_evars = {};
                for evar_idx = 1:numel(evar_colnames)
                    curr_evar_contents = [curr_events.(evar_colnames{evar_idx})];
                    if ~iscell(curr_evar_contents)
                        % Compute mean, then median
                        curr_evars{end + 1} = nanmean_bc(curr_evar_contents);
                        curr_evars{end + 1} = nanmedian_bc(curr_evar_contents);
                    else
                        curr_evars{end + 1} = nan;
                        curr_evars{end + 1} = nan;
                    end
                end
                all_evars(end + 1, :) = curr_evars;
                
                % Get set membership
                all_setmemberships{end + 1} = ismember(set_colnames, curr_set.name);
                % Get windowed data
                rel_lats = pupl_epoch_get(EYE(dataidx), epoch_selector, '_rel');
                rel_lats = [min(rel_lats(:, 1)) max(rel_lats(:, 2))];
                for winidx = 1:numel(win)
                    str_win = win{winidx};
                    curr_win = nan(size(str_win));
                    for ii = 1:2
                        if isempty(str_win{ii})
                            curr_win(ii) = rel_lats(ii);
                        else
                            curr_win(ii) = parsetimestr(str_win{ii}, EYE(dataidx).srate, 'smp');
                        end
                    end
                    rel_lats = unfold(rel_lats);
                    rel_win = rel_lats >= curr_win(1) & rel_lats <= curr_win(2);
                    collected_windows{setidx, winidx} = rel_win;
                    collected_epochidx{setidx, winidx} = epochidx;
                end
                printprog(setidx);
            end
    end
    %% Next, compute downsampling/statistics on data in cell array
    
    % Determine condition membership
    curr_condmemberships = ismember(...
        cond_colnames,...
        EYE(dataidx).cond);
    all_condmemberships = [
        all_condmemberships
        repmat({curr_condmemberships}, size(collected_windows, 1), 1)
    ];

    % Use data
    fprintf('Computing statistics on windowed data\t');
    printprog('setmax', 10)
    nwin = size(collected_windows, 1);
    last_pct = 0;
    for trialidx = 1:nwin
        curr_pct = round(10 * trialidx / nwin);
        if curr_pct > last_pct
            printprog(curr_pct)
            last_pct = curr_pct;
        end 
        switch args.which
            case 'downsampled'
                epoch_selector = [];
                epoch_selector.idx = collected_epochidx{trialidx, 1};
                data_type = {'pupil' 'both'};
                [curr_data, rej, ~, bef_aft, rel_lats] = pupl_epoch_getdata(...
                    EYE(dataidx),...
                    epoch_selector,...
                    data_type{:});
                if numel(bef_aft) > 1
                    if isequal(bef_aft{:})
                        rel_lats = rel_lats{1};
                        bef_aft = bef_aft{1};
                    else
                        error('Inconsistent epoching: some epochs begin before timelocking events while others end after')
                    end
                else
                    rel_lats = rel_lats{:};
                    bef_aft = bef_aft{:};
                end
                switch args.trialwise
                    case per_epoch
                        curr_data = curr_data{1}(collected_windows{trialidx, 1});
                    case set_avg
                        curr_data = cell2mat(curr_data);
                        curr_data = nanmean_bc(curr_data(~rej, collected_windows{trialidx, 1}), 1);
                end
                win_width = parsetimestr(args.cfg.width, EYE(dataidx).srate, 'smp');
                if isempty(args.cfg.step)
                    win_step = win_width;
                else
                    win_step = parsetimestr(args.cfg.step, EYE(dataidx).srate, 'smp');
                end
                
                rel_lats = unfold(rel_lats);
                ur_win = 1:win_width;
                
                if strcmp(bef_aft, 'before')
                    curr_data = fliplr(curr_data);
                end
                
                curr_win_starts = {};
                curr_win_ends = {};
                curr_ds = {};
                ii = 0;
                while true
                    curr_win = ur_win + win_step * ii;
                    ii = ii + 1;
                    if curr_win(end) > numel(curr_data)
                        break
                    else
                        curr_ds{end + 1} = nanmean_bc(curr_data(curr_win));
                        curr_win_starts{end + 1} = rel_lats(curr_win(1));
                        curr_win_ends{end + 1} = rel_lats(curr_win(end));
                    end
                end
                all_data_rows{end + 1} = [curr_ds{:}];
                all_win_starts{end + 1} = [curr_win_starts{:}];
                all_win_ends{end + 1} = [curr_win_ends{:}];
                if strcmp(bef_aft, 'before')
                    all_data_rows{end + 1} = fliplr(all_data_rows{end + 1});
                    all_win_starts{end + 1} = fliplr(all_win_starts{end + 1});
                    all_win_ends{end + 1} = fliplr(all_win_ends{end + 1});
                end
                all_bef_aft{end + 1} = bef_aft;
            case 'stats'
                % Compute statistics on vector
                curr_stats = [];
                epoch_selector = [];
                for winidx = 1:size(collected_windows, 2)
                    epoch_selector.idx = collected_epochidx{trialidx, winidx};
                    cache = []; % Speeds things up a bit
                    for statidx = 1:numel(args.cfg(winidx).stats)
                        statname = args.cfg(winidx).stats{statidx};
                        statoptidx = strcmp(statname, stat_opts(:, 1));
                        data_type = stat_opts{statoptidx, 4};
                        if isempty(data_type)
                            data_type = {'pupil' 'both'};
                        end
                        if isnonemptyfield(cache, data_type{:})
                            tmp = getfield(cache, data_type{:});
                            curr_data = tmp.data;
                            rej = tmp.rej;
                        else
                            [curr_data, rej] = pupl_epoch_getdata(...
                                EYE(dataidx),...
                                epoch_selector,...
                                data_type{:});
                            tmp = struct(...
                                'data', {curr_data},...
                                'rej', {rej});
                            cache = setfield(cache, data_type{:}, tmp);
                        end
                        
                        switch args.trialwise
                            case per_epoch
                                curr_win = curr_data{1}(collected_windows{trialidx, winidx});
                            case set_avg
                                curr_data = cell2mat(curr_data);
                                curr_data = curr_data(~rej, collected_windows{trialidx, winidx});
                                if isnumeric(curr_data)
                                    curr_win = nanmean_bc(curr_data, 1);
                                else
                                    curr_win = mat2cell(curr_data, ones(size(curr_data, 1), 1), size(curr_data, 2));
                                end
                        end
                        curr_func = str2func(func2str(stat_opts{statoptidx, 2}));
                        other_args = {};
                        if nargin(curr_func) == 2
                            % data structure also provided as input
                            other_args = {EYE(dataidx)};
                        end
                        if iscell(curr_win)
                            % take average of individual epoch statistics
                            tmp_stats = nan(size(curr_win));
                            for tmp_idx = 1:numel(curr_win)
                                tmp_stats(tmp_idx) = feval(curr_func, curr_win{tmp_idx}, other_args{:});
                            end
                            curr_stat = nanmean_bc(tmp_stats);
                        else
                            curr_stat = feval(curr_func, curr_win, other_args{:});
                        end
                        curr_stats = [curr_stats curr_stat];
                    end
                end
                all_data_rows{end + 1} = curr_stats;
        end
    end
end
fprintf('Done\n');

% Get data column names
switch args.which
    case 'downsampled'
        % Treat as wide format before we rotate to long format
        
        srate = EYE(1).srate; % Ensured earlier that sample rates were consistent
        
        max_cols = max(cellfun(@numel, all_data_rows));

        for row_idx = 1:numel(all_data_rows)
            n_missing = max_cols - numel(all_data_rows{row_idx});
            if n_missing > 1
                new_nans = nan(1, n_missing);
                switch all_bef_aft{row_idx}
                    case 'before'
                        all_data_rows{row_idx} = [new_nans all_data_rows{row_idx}];
                        
                        win_step = diff(all_win_starts{dataidx}(1:2));
                        
                        curr_starts = all_win_starts{dataidx};
                        new_starts = (curr_starts(1) - n_missing*win_step) : (curr_starts(1) - win_step);
                        all_win_starts{dataidx} = [new_starts all_win_starts{dataidx}];
                        
                        curr_ends = all_win_ends{dataidx};
                        new_ends = (curr_ends(1) - n_missing*win_step) : (curr_ends(1) - win_step);
                        all_win_ends{dataidx} = [new_ends all_win_ends{dataidx}];
                    case 'after'
                        all_data_rows{row_idx} = [all_data_rows{row_idx} new_nans];
                        
                        win_step = diff(all_win_starts{dataidx}(1:2));
                        
                        curr_starts = all_win_starts{dataidx};
                        new_starts = (curr_starts(1) + win_step) : (curr_starts(1) + n_missing*win_step);
                        all_win_starts{dataidx} = [all_win_starts{dataidx} new_starts];
                        
                        curr_ends = all_win_ends{dataidx};
                        new_ends = (curr_ends(1) - win_step) : (curr_ends(1) + n_missing*win_step);
                        all_win_ends{dataidx} = [all_win_ends{dataidx} new_ends];
                end
            end
        end
        
        if isempty(args.cfg.step)
            win_step = win_width;
        else
            win_step = parsetimestr(args.cfg.step, srate, 'smp');
        end
        
        switch args.lw
            case 'wide'
                data_colnames = strcat(...
                    't',...
                    cellfun(@num2str, num2cell(1:max_cols), 'UniformOutput', false)...
                );
                if all(diff(sort(unique([all_win_starts{:}]))) == win_step)
                    t_win_starts = (min([all_win_starts{:}]):win_step:max([all_win_starts{:}])) / srate;
                    t_win_ends = (min([all_win_ends{:}]):win_step:max([all_win_ends{:}])) / srate;
                    data_colnames = strcat(...
                        data_colnames,...
                        '_',...
                        cellfun(@num2str, num2cell(t_win_starts), 'UniformOutput', false),...
                        '_',...
                        cellfun(@num2str, num2cell(t_win_ends), 'UniformOutput', false)...
                    );
                else
                    warning_txt = {
                        'Downsampled windows could not be aligned'
                        'I.e., between epochs, downsampling windows overlap only partially in some cases'
                        'Columns in the data table will not contain the beginnings and ends of the downsampling windows'
                    };
                    warning('%s\n', warning_txt{:});
                end
                
            case 'long'
                epoch_units = mergefields(EYE, 'units', 'epoch');
                epoch_size = epoch_units(1:3:end);
                if isequal(epoch_size{:})
                    data_colnames = sprintf('pupil_%s', EYE(1).units.epoch{1});
                else
                    data_colnames = 'pupil_size';
                end
                all_data_rows = num2cell([all_data_rows{:}]');
        end
    case 'stats'
        data_colnames = {};
        for ii = 1:numel(args.cfg)
            data_colnames = [data_colnames strcat(args.cfg(ii).name, '_', args.cfg(ii).statsnames)];
        end
end
all_data_rows = num2cell(cell2mat(all_data_rows(:)));
all_info = all_info(:);
all_setmemberships = num2cell(cell2mat(all_setmemberships(:)));
all_condmemberships = num2cell(cell2mat(all_condmemberships(:)));

if strcmp(args.trialwise, per_epoch)
    evar_colnames = strcat('evar_', evar_colnames);
else
    evar_colnames = strcat('evar_', evar_colnames);
    evar_colnames = [
        strcat(evar_colnames, '_mean')
        strcat(evar_colnames, '_median')
    ];
    evar_colnames = evar_colnames(:)';
end

nondata_table = [
    info_colnames   trial_colnames  evar_colnames   strcat('cond_', cond_colnames)  strcat('set_', set_colnames)
    all_info        all_trialinfo   all_evars       all_condmemberships             all_setmemberships
];

if strcmp(args.trialwise, set_avg)
    epoch_set = [
        {'epoch_set'}
        all_epochsets(:)
    ];
    nondata_table = [nondata_table epoch_set];
end

data_table = [
    data_colnames
    all_data_rows
];

if strcmp(args.which, 'downsampled')
    if strcmp(args.lw, 'long')
        % Reshape to long format
        prev_size = size(nondata_table);
        cols = nondata_table(1, :);
        contents = nondata_table(2:end, :);
        contents = repmat(contents', max_cols, 1); % max_cols defined during the naming of the data columns
        contents = reshape(contents, prev_size(2), [])';
        nondata_table = [
            cols
            contents
        ];
    
        se = [
            {'win_start'} {'win_end'}
            num2cell([[all_win_starts{:}]' [all_win_ends{:}]']/srate)
        ];
        nondata_table = [nondata_table se];
    end
end

bigtable = [nondata_table data_table];

fprintf('Writing to %s...', args.path);
writecell2delim(args.path, bigtable, ',');
fprintf('Done\n');

if ~isempty(gcbf)
    global pupl_globals
    args = pupl_struct2args(args);
    fprintf('\nEquivalent command:\n\n%s(%s, %s)\n\n', mfilename, pupl_globals.datavarname, all2str(args{:}));
end

end