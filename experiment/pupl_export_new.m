function pupl_export_new(EYE, varargin)

%% Get missing args

args = pupl_args2struct(varargin, {
    'which' []
    'cfg' []
    'trialwise' []
    'path' []
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
                'step' 'Step size (defaults to width plus one sample/datapoint)' ''
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
        trial_colnames = {'trial_type' 'trial_idx' 'rejected' 'rt'};
        tvar_colnames = pupl_tvar_getnames(mergefields(EYE, 'event'));
        tvar_colnames = tvar_colnames(:)';
    otherwise
        trial_colnames = {'mean_rt' 'median_rt' 'mean_log_rt'};
        tvar_colnames = [];
end
all_info = {};
all_condmemberships = {};
all_setmemberships = {};
all_trialinfo = {};
all_tvars = {};
all_data = {};

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
                    curr_event.rt
                };
                % Get trial vars
                curr_tvars = {};
                for tvar_idx = 1:numel(tvar_colnames)
                    curr_tvars{end + 1} = curr_event.(tvar_colnames{tvar_idx});
                end
                all_tvars(end + 1, :) = curr_tvars;
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
                    is_win = rel_lats >= curr_win(1) & rel_lats <= curr_win(2);
                    abs_lats = rel_lats(is_win) + pupl_epoch_get(EYE(dataidx), curr_epoch, '_lat');
                    collected_windows{epochidx, winidx} = abs_lats;
                end
                rec_idx{end + 1} = dataidx;
            end
        case set_avg
            fprintf('Collecting windowed data\t\t\t\t');
            collected_windows = cell(numel(EYE(dataidx).epochset), numel(win));
            n_sets = numel(EYE(dataidx).epochset);
            printprog('setmax', n_sets);
            for setidx = 1:n_sets
                curr_set = EYE(dataidx).epochset(setidx);
                epochidx = pupl_epoch_sel(EYE(dataidx), EYE(dataidx).epoch, curr_set.description.members);
                rts = pupl_epoch_get(EYE(dataidx), EYE(dataidx).epoch(epochidx), 'rt');
                % Get epoch info
                all_info{end + 1} = EYE(dataidx).name;
                all_trialinfo(end + 1, :) = {
                    nanmean_bc(rts)
                    nanmedian_bc(rts)
                    nanmean_bc(log(rts))
                };
                % Get set membership
                all_setmemberships{end + 1} = ismember(set_colnames, curr_set.description.name);
                % Get windowed data
                curr_data = nanmean_bc(cell2mat(pupl_epoch_getdata(EYE(dataidx), curr_set.name)));
                for winidx = 1:numel(win)
                    str_win = win{winidx};
                    curr_win = nan(size(str_win));
                    for ii = 1:2
                        if isempty(str_win{ii})
                            curr_win(ii) = parsetimestr(EYE(dataidx).epochset(setidx).lims(ii), EYE(dataidx).srate, 'smp');
                        else
                            curr_win(ii) = parsetimestr(str_win{ii}, EYE(dataidx).srate, 'smp');
                        end
                    end
                    rel_lats = unfold(parsetimestr(EYE(dataidx).epochset(setidx).lims, EYE(dataidx).srate, 'smp'));
                    win_idx = rel_lats >= curr_win(1) & rel_lats <= curr_win(2);
                    collected_windows{setidx, winidx} = curr_data(win_idx);
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
                if strcmp(args.trialwise, per_epoch)
                    curr_data = getfield(EYE(dataidx), 'pupil', 'both');
                    curr_data = curr_data(collected_windows{trialidx, winidx});
                else
                    curr_data = collected_windows{trialidx, 1};
                end
                win_width = parsetimestr(args.cfg.width, EYE(dataidx).srate, 'smp');
                % 1s at 60Hz gives 60 datapoints
                if isempty(args.cfg.step)
                    win_step = win_width + 1;
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
                        switch args.trialwise
                            case per_epoch
                                data_type = stat_opts{statoptidx, 4};
                                if isempty(data_type)
                                    data_type = {'pupil' 'both'};
                                end
                                curr_data = getfield(EYE(dataidx), data_type{:});
                                curr_win = curr_data(collected_windows{trialidx, winidx});
                            case set_avg
                                curr_win = collected_windows{trialidx, winidx};
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
        n_data_cols = max(cellfun(@numel, all_data));
        data_colnames = arrayfun(@(n) sprintf('t%d', n), 1:n_data_cols, 'UniformOutput', false);
        for idx = 1:numel(all_data)
            n_missing = n_data_cols - numel(all_data{idx});
            all_data{idx} = [all_data{idx} nan(1, n_missing)];
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
    tvar_colnames = strcat('tvar_', tvar_colnames);
else
    all_tvars = [];
end

bigtable = [
    info_colnames   trial_colnames  tvar_colnames   strcat('cond_', cond_colnames)  strcat('set_', set_colnames)    data_colnames
    all_info        all_trialinfo   all_tvars       all_condmemberships             all_setmemberships              all_data
];

fprintf('Writing to %s...', args.path);
writecell2delim(args.path, bigtable, ',');
fprintf('Done\n');

if ~isempty(gcbf)
    global pupl_globals
    args = pupl_struct2args(args);
    fprintf('\nEquivalent command:\n\n%s(%s, %s)\n\n', mfilename, pupl_globals.datavarname, all2str(args{:}));
end

end