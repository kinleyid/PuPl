function pupl_export_new(EYE, varargin)

%% Get missing args

args = pupl_args2struct(varargin, {
    'which' []
    'cfg' []
    'trialwise' []
    'path' []
    'lw' []
});

stat_opts = [
%   {Name presented to user} {function} {column name in spreadsheet} {type of data used for computation (if empty, {'pupil' 'both'})}
    {'Mean'} {@nanmean_bc} {'mean'} {[]};...
    {'Peak-to-peak difference'} {@(x)(max(x) - min(x))} {'peak_to_peak_diff'} {[]};...
    {'Max'} {@max} {'max'} {[]};...
    {'Min'} {@min} {'min'} {[]};...
    {'Median'} {@nanmedian_bc} {'median'} {[]};...
    {'Standard deviation'} {@nanstd_bc} {'stdev'} {[]};...
    {'Variance'} {@nanvar_bc} {'variance'} {[]};...
    {'Percent missing'} {@(x)100*nnz(isnan(x))/numel(x)} {'pct_missing'} {[]}
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

if strcmp(args.trialwise, per_epoch)
    stat_opts = [
        stat_opts
        {'Number of blinks'} {@(x)nnz(diff(x=='b')==1)} {'n_blinks'} {{'datalabel'}}
        {'Number of saccades'} {@(x)nnz(diff(x(1:end-1)=='s')==1)} {'n_sacc'} {{'interstices'}}
    ];
end

if isempty(args.cfg)
    switch args.which
        case 'downsampled'
            fields = {
                % field | prompt | default
                'start' 'Start (relative to epoch-defining event; defaults to start of epoch)' EYE(1).epoch(1).lims{1}
                'width' 'Width' '100ms'
                'step' 'Step size (defaults to width)' ''
                'end' 'End (relative to epoch-defining event; defaults to end of epoch)' EYE(1).epoch(1).lims{2}
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
                win = (inputdlg(...
                    {sprintf('Define statistics time window centred on trial-defining events (if left empty, the window start and end default to the beginning and end of epoch, respectively)\n\nWindow start:')
                    'Window end:'}));
                if isempty(win)
                    return
                else
                    str_win = win;
                    if isempty(win{1})
                        str_win{1} = 'start of epoch';
                    end
                    if isempty(win{2})
                        str_win{2} = 'end of epoch';
                    end
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
        trial_colnames = {'trial_type' 'trial_idx' 'rejected'};
        evar_colnames = pupl_evar_getnames(mergefields(EYE, 'event'));
        evar_colnames = evar_colnames(:)';
    otherwise
        evar_colnames = [];
        trial_colnames = {'mean_rt' 'median_rt' 'mean_log_rt'};
        get_rts = isfield(mergefields(EYE, 'event'), 'rt');
end
all_info = {};
all_condmemberships = {};
all_setmemberships = {};
all_trialinfo = {};
all_evars = {};
all_data = {};
all_epochidx = {};

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
            for epochidx = 1:n_epochs
                % Print progress
                curr_pct = round(10 * epochidx / n_epochs);
                if curr_pct > last_pct
                    printprog(curr_pct);
                    last_pct = curr_pct;
                end
                % Get epoch info
                all_info{end + 1} = EYE(dataidx).name;
                curr_epoch = EYE(dataidx).epoch(epochidx);
                curr_event = pupl_epoch_get(EYE(dataidx), curr_epoch, '_ev');
                all_trialinfo(end + 1, :) = {
                    sprintf('"%s"', curr_event.name)
                    epochidx
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
                    str_win = win{winidx};
                    if isempty(str_win{1})
                        str_win{1} = curr_epoch.lims{1};
                    end
                    if isempty(str_win{2})
                        str_win{2} = curr_epoch.lims{2};
                    end
                    curr_win = parsetimestr(str_win, EYE(dataidx).srate, 'smp');
                    rel_lats = unfold(parsetimestr(curr_epoch.lims, EYE(dataidx).srate, 'smp'));
                    rel_win = rel_lats >= curr_win(1) & rel_lats <= curr_win(2);
                    collected_windows{epochidx, winidx} = rel_win;
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
                epochidx = pupl_epoch_sel(EYE(dataidx), EYE(dataidx).epoch, curr_set.members);
                % Get epoch info
                all_info{end + 1} = EYE(dataidx).name;
                if get_rts
                    rts = pupl_epoch_get(EYE(dataidx), EYE(dataidx).epoch(epochidx), 'rt');
                    all_trialinfo(end + 1, :) = {
                        nanmean_bc(rts)
                        nanmedian_bc(rts)
                        nanmean_bc(log(rts))
                    };
                else
                    all_trialinfo(end + 1, :) = {
                        nan
                        nan
                        nan
                    };
                end
                % Get set membership
                all_setmemberships{end + 1} = ismember(set_colnames, curr_set.name);
                % Get windowed data
                curr_data = nanmean_bc(cell2mat(pupl_epoch_getdata(EYE(dataidx), curr_set.name)));
                for winidx = 1:numel(win)
                    str_win = win{winidx};
                    curr_win = nan(size(str_win));
                    for ii = 1:2
                        if isempty(str_win{ii})
                            lims = {EYE(dataidx).epoch(epochidx).lims};
                            if isequal(lims{:})
                                curr_win(ii) = parsetimestr(lims{1}{ii}, EYE(dataidx).srate, 'smp');
                            else
                                error('Epochs are not all of the same length');
                            end
                        else
                            curr_win(ii) = parsetimestr(str_win{ii}, EYE(dataidx).srate, 'smp');
                        end
                    end
                    if isequal(EYE(dataidx).epoch(epochidx).lims)
                        rel_lats = unfold(...
                            parsetimestr(...
                                EYE(dataidx).epoch(find(epochidx, 1)).lims,...
                                EYE(dataidx).srate,...
                                'smp'));
                        rel_win = find(rel_lats >= curr_win(1) & rel_lats <= curr_win(2));
                        
                    else
                        rel_win = curr_win(1):curr_win(2);
                    end
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
                data_type = {'pupil' 'both'};
                switch args.trialwise
                    case per_epoch
                        curr_data = pupl_epoch_getdata(...
                            EYE(dataidx),...
                            collected_epochidx{trialidx, winidx},...
                            data_type{:});
                        curr_data = curr_data{1}(collected_windows{trialidx, winidx});
                    case set_avg
                        [curr_data, rej] = pupl_epoch_getdata(...
                            EYE(dataidx),...
                            collected_epochidx{trialidx, winidx},...
                            data_type{:});
                        curr_data = cell2mat(curr_data);
                        curr_data = nanmean_bc(curr_data(~rej, collected_windows{trialidx, winidx}), 1);
                end
                win_width = parsetimestr(args.cfg.width, EYE(dataidx).srate, 'smp');
                if isempty(args.cfg.step)
                    win_step = win_width;
                else
                    win_step = parsetimestr(args.cfg.step, EYE(dataidx).srate, 'smp');
                end

                ur_win = 1:win_width;

                curr_ds = {};
                ii = 0;
                while true
                    curr_win = ur_win + win_step * ii;
                    ii = ii + 1;
                    if curr_win(end) > numel(curr_data)
                        break
                    else
                        curr_ds{end + 1} = nanmean_bc(curr_data(curr_win));
                    end
                end
                all_data{end + 1} = [curr_ds{:}];
            case 'stats'
                % Compute statistics on vector
                curr_stats = [];
                for winidx = 1:size(collected_windows, 2)
                    for statidx = 1:numel(args.cfg(winidx).stats)
                        statname = args.cfg(winidx).stats{statidx};
                        statoptidx = strcmp(statname, stat_opts(:, 1));
                        data_type = stat_opts{statoptidx, 4};
                        if isempty(data_type)
                            data_type = {'pupil' 'both'};
                        end
                        switch args.trialwise
                            case per_epoch
                                curr_data = pupl_epoch_getdata(...
                                    EYE(dataidx),...
                                    collected_epochidx{trialidx, winidx},...
                                    data_type{:});
                                curr_win = curr_data{1}(collected_windows{trialidx, winidx});
                            case set_avg
                                [curr_data, rej] = pupl_epoch_getdata(...
                                    EYE(dataidx),...
                                    collected_epochidx{trialidx, winidx},...
                                    data_type{:});
                                curr_data = cell2mat(curr_data);
                                curr_win = nanmean_bc(curr_data(~rej, collected_windows{trialidx, winidx}), 1);
                        end
                        curr_stats = [curr_stats feval(stat_opts{statoptidx, 2}, curr_win)];
                    end
                end
                all_data{end + 1} = curr_stats;
        end
    end
end
fprintf('Done\n');

% Get data column names
switch args.which
    case 'downsampled'
        
        n_samples_per = max(cellfun(@numel, all_data));
        
        % Fill in missing samples
        for idx = 1:numel(all_data)
            n_missing = n_samples_per - numel(all_data{idx});
            all_data{idx} = [all_data{idx} nan(1, n_missing)];
        end
        
        if isequal(EYE.srate)
            srate = EYE(1).srate;
            win_start = parsetimestr(args.cfg.start, srate, 'smp');
            win_end = parsetimestr(args.cfg.end, srate, 'smp');
            win_width = parsetimestr(args.cfg.width, srate, 'smp');
            if isempty(args.cfg.step)
                win_step = win_width;
            else
                win_step = parsetimestr(args.cfg.step, srate, 'smp');
            end
            ur_win = 1:win_width;
            win_starts = (ur_win(1) + win_step * (0:n_samples_per-1)) / srate;
            win_ends = (ur_win(end) + win_step * (0:n_samples_per-1)) / srate;
        else
            win_starts = [];
            win_ends = [];
        end
        switch args.lw
            case 'wide'
                data_colnames = strcat(...
                    't',...
                    cellfun(@num2str, num2cell(1:n_samples_per), 'UniformOutput', false)...
                );
                if ~isempty(win_starts)
                    data_colnames = strcat(...
                        data_colnames,...
                        '[',...
                        cellfun(@num2str, num2cell(win_starts), 'UniformOutput', false),...
                        '_',...
                        cellfun(@num2str, num2cell(win_starts), 'UniformOutput', false),...
                        ']'...
                    );
                end
            case 'long'
                data_colnames = sprintf('pupil_%s', EYE(1).units.epoch{1});
                all_data = num2cell([all_data{:}]');
        end
    case 'stats'
        data_colnames = {};
        for ii = 1:numel(args.cfg)
            data_colnames = [data_colnames strcat(args.cfg(ii).name, '_', args.cfg(ii).statsnames)];
        end
end
all_data = num2cell(cell2mat(all_data(:)));
all_info = all_info(:);
all_setmemberships = num2cell(cell2mat(all_setmemberships(:)));
all_condmemberships = num2cell(cell2mat(all_condmemberships(:)));

if strcmp(args.trialwise, per_epoch)
    evar_colnames = strcat('evar_', evar_colnames);
else
    all_evars = [];
end

nondata_table = [
    info_colnames   trial_colnames  evar_colnames   strcat('cond_', cond_colnames)  strcat('set_', set_colnames)
    all_info        all_trialinfo   all_evars       all_condmemberships             all_setmemberships
];

data_table = [
    data_colnames
    all_data
];

if strcmp(args.which, 'downsampled')
    if strcmp(args.lw, 'long')
        % Reshape to long format
        prev_size = size(nondata_table);
        cols = nondata_table(1, :);
        contents = nondata_table(2:end, :);
        contents = repmat(contents', n_samples_per, 1);
        contents = reshape(contents, prev_size(2), [])';
        nondata_table = [
            cols
            contents
        ];
        if ~isempty(win_starts)
            se = [num2cell(win_starts(:)) num2cell(win_ends(:))];
            se = repmat(se, prev_size(1) - 1, 1);
            se = [
                {'win_start'} {'win_end'}
                se
            ];
            nondata_table = [nondata_table se];
        end
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