
function pupl_stats(EYE, varargin)

%   Inputs
% stat--
% win--either a numeric vector of 2 latencies or a cell array of 2 time strings
% byTrial--true or false

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

args = pupl_args2struct(varargin, {
    'cfg' []
    'trialwise' []
    'fullpath' []
});

if isempty(args.cfg)
    while true
        win = (inputdlg(...
            {sprintf('Define statistics time window centred on trial-defining events\n\nWindow start:')
            'Window end:'}));
        if isempty(win)
            return
        end
        name = (inputdlg(...
            {sprintf('Name of statistics time window from %s to %s', win{:})}));
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

if isempty(args.fullpath)
    [file, dir] = uiputfile('*.csv');
    if isnumeric(file)
        return
    end
    args.fullpath = fullfile(dir, file);
end

info_colnames = {'recording'}; % Data columns will be added afterward
cond_colnames = unique(mergefields(EYE, 'cond')); % Condition membership
set_colnames = unique(mergefields(EYE, 'epochset', 'name')); % Set membership
all_info = {};
all_condmemberships = {};
all_setmemberships = {};
all_data = {};

switch trialwise
    case per_epoch
        trial_colnames = {'trial_idx' 'trial_type' 'rejected' 'rt'};
    otherwise
        trial_colnames = {'mean_rt' 'median_rt' 'mean_log_rt'};
end

stat_colnames = [];
for ii = 1:numel(args.cfg)
    stat_colnames = [stat_colnames strcat(args.cfg(ii).name, '_', args.cfg(ii).stats)];
end

fprintf('Computing statistics...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    
    switch cfg.trialwise % How to iterate through data?
        case per_epoch % Iterate over epochs
            itermax = numel(EYE(dataidx).epoch);
        otherwise % Iterate over trial sets
            itermax = numel(EYE(dataidx).epochset);
    end
    
    % Get logical vector indicating experimental condition
    curr_condmemberships = ismember(...
        cond_colnames,...
        EYE(dataidx).cond);
    all_condmemberships = [
        all_condmemberships
        repmat({curr_condmemberships}, itermax, 1)
    ];
    
    switch cfg.trialwise
        case per_epoch
            
        case set_avg
            % Iterate over 
    end

    for iterator = 1:itermax
        for winidx = 1:numel(args.cfg)
            currwin = parsetimestr(args.cfg(winidx).win, EYE(dataidx).srate, 'smp');
            % Get data as vector, plus other columns of the new data table
            % row:
            switch trialwise
                case per_epoch
                    rellats = unfold(EYE(dataidx).epoch(iterator).rellims);
                    data = EYE(dataidx).diam.both(unfold(EYE(dataidx).epoch(epochidx).abslims));
                    isrej = EYE(dataidx).epoch(epochidx).reject;
                    latidx = find(rellats == currwin(1)):find(rellats == currwin(2));
                    data = data(latidx);
                    rtstat = EYE(dataidx).epoch(iterator).event.rt;
                    % Figure out trial set membership
                    trialSetVec = [];
                    for trialsetname = uniqueTrialSetNames
                        trialsetidx = strcmp({EYE(dataidx).trialset.name}, trialsetname);
                        if ismember(EYE(dataidx).epoch(iterator).name, EYE(dataidx).trialset(trialsetidx).description.members)
                            newVal = true;
                        else
                            newVal = false;
                        end
                        trialSetVec = [trialSetVec newVal];
                    end
                otherwise
                    rellats = unfold(EYE(dataidx).trialset(iterator).rellims);
                    if isempty(rellats)
                        warning('You have combined epochs into a bin that do not all begin and end at the same time relative to their events');
                        latidx = currwin(1):currwin(2);
                    else
                        latidx = find(rellats == currwin(1)):find(rellats == currwin(2));
                    end
                    [data, isrej] = gettrialsetdatamatrix(EYE(dataidx), EYE(dataidx).trialset(setidx).name);
                    data = nanmean_bc(data(~isrej, latidx));
                    epochidx = getepochidx(EYE(dataidx), EYE(dataidx).trialset(iterator).description);
                    rtstat = nanmean_bc(mergefields(EYE(dataidx).epoch(epochidx), 'event', 'rt')); % Mean reaction time
                    trialSetVec = ismember(uniqueTrialSetNames, EYE(dataidx).trialset(iterator).name);
            end
            % Compute statistics of vector
            nStats = numel(args.cfg(winidx).stats);
            currStats = nan(1, nStats);
            for statidx = 1:nStats
                statname = args.cfg(winidx).stats{statidx};
                statoptidx = strcmp(statname, stat_opts(:, 1));
                currStats(statidx) = feval(stat_opts{statoptidx, 2}, data);
            end
            
            currRow = [
                EYE(dataidx).name... Dataset name
                condVec... Logical vector indicating experimental condition membership
                trialSetVec... Logical vector indicating trial set membership
                rtstat... Reaction time, either individual or trial set average
            ];
            switch trialwise
                case per_epoch
                    newCols = [
                        isrej... Rejected
                        iterator... TrialIdx
                        EYE(datadix).epoch(iterator).name... TrialType
                    ];
                otherwise
                    newCols = [];
            end
            statsTable = [
                statsTable
                [currRow newCols]
            ];
        end
    end
    fprintf('done\n');
end

fprintf('Writing to table...\n');
writecell2delim(fullpath, statsTable, ',');
fprintf('Done\n');

if ~isempty(gcbf)
    fprintf('Equivalent command: %s\n', getcallstr(p, false));
end

end