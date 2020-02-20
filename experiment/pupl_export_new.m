function pupl_export_new(EYE, varargin)

%% Get missing args

args = pupl_args2struct(varargin, {
    'which' []
    'cfg' []
    'trialwise' []
    'path' []
});

stat_opts = [
%   {Name presented to user} {function} {column name in spreadsheet}
    {'Mean'} {@nanmean_bc} {'Mean'};...
    {'Peak-to-peak difference'} {@(x)(max(x) - min(x))} {'PeakToPeakDiff'};...
    {'Max'} {@max} {'Max'};...
    {'Min'} {@min} {'Min'};...
    {'Median'} {@nanmedian_bc} {'Median'};...
    {'Standard deviation'} {@nanstd_bc} {'StDev'};...
    {'Variance'} {@nanvar_bc} {'Variance'};...
    {'Percent missing'} {@(x)100*nnz(isnan(x))/numel(x)} {'PctMissing'};...
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
                end
                args.cfg = [
                    args.cfg...
                    struct(...
                        'name', name,...
                        'win', {win},...
                        'stats', {stats})
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
        trial_colnames = {'trial_idx' 'trial_type' 'rejected' 'rt'};
    otherwise
        trial_colnames = {'mean_rt' 'median_rt' 'mean_log_rt'};
end
all_info = {};
all_condmemberships = {};
all_setmemberships = {};
all_trialinfo = {};
all_data = {};

% All data will be windowed. 
switch args.which
    case 'downsampled'
        win = {{args.cfg.start args.cfg.end}};
    case 'stats'
        win = {args.cfg.win};
end

fprintf('Getting data...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...\n', EYE(dataidx).name);
    
    %% First, collect windowed data in a cell array
    switch args.trialwise
        case per_epoch
            data = cell(numel(EYE(dataidx).epoch), numel(win));
            for epochidx = 1:numel(EYE(dataidx).epoch)
                % Get epoch info
                all_info{end + 1} = EYE(dataidx).name;
                all_trialinfo(end + 1, :) = {
                    EYE(dataidx).epoch(epochidx).name
                    epochidx
                    EYE(dataidx).epoch(epochidx).reject
                    EYE(dataidx).epoch(epochidx).event.rt
                };
                % Determine set membership, lining up membership with column names
                curr_setnames = {EYE(dataidx).epochset.name};
                curr_setmembership = curr_setnames(...
                    arrayfun(...
                        @(desc) ismember(...
                            EYE(dataidx).epoch(epochidx).name,...
                            desc.members),...
                        [EYE(dataidx).epochset.description]));
                all_setmemberships{end + 1} = ismember(set_colnames, curr_setmembership);
                % Get windowed data
                curr_data = pupl_epoch_getdata(EYE(dataidx), epochidx);
                curr_data = curr_data{1};
                curr_epoch = EYE(dataidx).epoch(epochidx);
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
                    win_idx = rel_lats >= curr_win(1) & rel_lats <= curr_win(2);
                    data{epochidx, winidx} = curr_data(win_idx);
                end
            end
        case set_avg
            data = cell(numel(EYE(dataidx).epochset), numel(win));
            for setidx = 1:numel(EYE(dataidx).epochset)
                curr_set = EYE(dataidx).epochset(setidx);
                epochidx = ismember({EYE(dataidx).epoch.name}, curr_set.description.members);
                rts = mergefields(EYE(dataidx).epoch(epochidx), 'event', 'rt');
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
                            curr_win(ii) = EYE(dataidx).epochset(setidx).rellims(ii);
                        else
                            curr_win(ii) = parsetimestr(str_win{ii}, EYE(dataidx).srate, 'smp');
                        end
                    end
                    rel_lats = unfold(EYE(dataidx).epochset(setidx).rellims);
                    win_idx = rel_lats >= curr_win(1) & rel_lats <= curr_win(2);
                    data{setidx, winidx} = curr_data(win_idx);
                end
            end
    end
    %% Next, compute downsampling/statistics on data in cell array
    
    % Determine condition membership
    curr_condmemberships = ismember(...
        cond_colnames,...
        EYE(dataidx).cond);
    all_condmemberships = [
        all_condmemberships
        repmat({curr_condmemberships}, size(data, 1), 1)
    ];

    % Use data
    for trialidx = 1:size(data, 1)
        switch args.which
            case 'downsampled'
                curr_data = data{trialidx, 1};
                win_width = parsetimestr(args.cfg.width, EYE(dataidx).srate, 'smp');
                % 1s at 60Hz gives 60 datapoints
                if isempty(args.cfg.step)
                    win_step = win_width + 1;
                else
                    win_step = parsetimestr(args.cfg.step, EYE(dataidx).srate, 'smp');
                end

                win = 1:win_width;

                curr_ds = {};
                ii = 0;
                while true
                    curr_win = win + win_step * ii;
                    ii = ii + 1;
                    if curr_win(end) > numel(curr_data)
                        break
                    else
                        curr_ds{end + 1} = nanmean_bc(EYE(dataidx).pupil.both(curr_win));
                    end
                end
                all_data{end + 1} = [curr_ds{:}];
            case 'stats'
                % Compute statistics on vector
                curr_stats = [];
                for winidx = 1:size(data, 2)
                    for statidx = 1:numel(args.cfg(winidx).stats)
                        statname = args.cfg(winidx).stats{statidx};
                        statoptidx = strcmp(statname, stat_opts(:, 1));
                        curr_stats = [curr_stats feval(stat_opts{statoptidx, 2}, data{trialidx, winidx})];
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
        data_colnames = [];
        for ii = 1:numel(args.cfg)
            data_colnames = [data_colnames strcat(args.cfg(ii).name, '_', args.cfg(ii).stats)];
        end
end
all_data = num2cell(cell2mat(all_data(:)));
all_info = all_info(:);
all_setmemberships = num2cell(cell2mat(all_setmemberships(:)));
all_condmemberships = num2cell(cell2mat(all_condmemberships(:)));

bigtable = [
    info_colnames   trial_colnames   strcat('cond_', cond_colnames)  strcat('set_', set_colnames)    data_colnames
    all_info        all_trialinfo    all_condmemberships             all_setmemberships              all_data
];

fprintf('Writing to %s...\n', args.path);
writecell2delim(args.path, bigtable, ',');
fprintf('Done\n');

end