function pupl_export(EYE, varargin)

args = pupl_args2struct(varargin, {
    'cfg' []
    'path' []
});

if isempty(args.cfg)
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
end

if isempty(args.path)
    [f, d] = uiputfile('*.csv');
    if isnumeric(f)
        return
    end
    args.path = fullfile(d, f);
end

info_colnames = {'recording' 'trial_type' 'trial_idx' 'rejected' 'rt'}; % Data columns will be added afterward
cond_colnames = unique(mergefields(EYE, 'cond')); % Condition membership
set_colnames = unique(mergefields(EYE, 'epochset', 'name')); % Set membership
all_info = {};
all_condmemberships = {};
all_setmemberships = {};
all_data = {};

fprintf('Getting data...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    
    % Determine condition membership
    curr_condmemberships = ismember(...
        cond_colnames,...
        EYE(dataidx).cond);
    all_condmemberships = [
        all_condmemberships
        repmat({curr_condmemberships}, numel(EYE(dataidx).epoch), 1)
    ];
    
    win_width = -1 + parsetimestr(args.cfg.width, EYE(dataidx).srate, 'smp');
    % The -1 in the above line is so that 1s at 60Hz gives 60 datapoints
    if isempty(args.cfg.step)
        win_step = win_width + 1;
    else
        win_step = parsetimestr(args.cfg.step, EYE(dataidx).srate, 'smp');
    end
    curr_setdescriptions = [EYE(dataidx).epochset.description];
    curr_setnames = {EYE(dataidx).epochset.name};
    for epochidx = 1:numel(EYE(dataidx).epoch)
        % Get epoch info
        all_info(end + 1, :) = {
            EYE(dataidx).name
            cellfun(@(n) sprintf('"%s"', n), {EYE(dataidx).epoch(epochidx).name})
            epochidx
            EYE(dataidx).epoch(epochidx).reject
            EYE(dataidx).epoch(epochidx).event.rt
        };
        
        % Get data
        event_lat = EYE(dataidx).epoch(epochidx).event.latency;
        start_str = args.cfg.start;
        if isempty(start_str)
            start_str = EYE(dataidx).epoch(epochidx).lims{1};
        end
        win_start = parsetimestr(start_str, EYE(dataidx).srate, 'smp');
        end_str = args.cfg.end;
        if isempty(end_str)
            end_str = EYE(dataidx).epoch(epochidx).lims{2};
        end
        abs_end = parsetimestr(end_str, EYE(dataidx).srate, 'smp') + event_lat;

        win = event_lat + [
            win_start 
            win_start + win_width
        ];

        curr_data = {};
        ii = 0;
        while true
            curr_win = win + win_step * ii;
            ii = ii + 1;
            if curr_win(2) > abs_end
                break
            else
                curr_data{end + 1} = nanmean_bc(EYE(dataidx).pupil.both(unfold(curr_win)));
            end
        end
        all_data{end + 1} = [curr_data{:}];
        
        % Determine set membership, lining up membership with column names
        curr_setmembership = curr_setnames(...
            arrayfun(...
                @(desc) ismember(...
                    EYE(dataidx).epoch(epochidx).name,...
                    desc.members),...
                curr_setdescriptions));
        all_setmemberships{end + 1} = ismember(set_colnames, curr_setmembership);
                
    end
    fprintf('done\n');
end
fprintf('Done\n');

n_data_cols = max(cellfun(@numel, all_data));
data_colnames = arrayfun(@(n) sprintf('t%d', n), 1:n_data_cols, 'UniformOutput', false);
for idx = 1:numel(all_data)
    n_missing = n_data_cols - numel(all_data{idx});
    all_data{idx} = [all_data{idx} nan(1, n_missing)];
end
all_data = num2cell(cell2mat(all_data(:)));

all_setmemberships = num2cell(cell2mat(all_setmemberships(:)));
all_condmemberships = num2cell(cell2mat(all_condmemberships(:)));

bigtable = [
    info_colnames   strcat('cond_', cond_colnames)  strcat('set_', set_colnames)    data_colnames
    all_info        all_condmemberships             all_setmemberships              all_data
];

fprintf('Writing to %s...\n', args.path);
writecell2delim(args.path, bigtable, ',');
fprintf('Done\n');

end