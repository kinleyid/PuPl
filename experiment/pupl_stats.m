
function pupl_stats(EYE, varargin)

%   Inputs
% stat--
% win--either a numeric vector of 2 latencies or a cell array of 2 time strings
% byTrial--true or false

statOptions = [
%   {Name presented to user} {function} {column name in stats spreadsheet}
    {'Mean'} {@nanmean_bc} {'Mean'};...
    {'PeakToPeakDiff'} {@(x)(max(x) - min(x))} {'PeakToPeakDiff'};...
    {'Max'} {@max} {'Max'};...
    {'Min'} {@min} {'Min'};...
    {'Median'} {@nanmedian_bc} {'Median'};...
    {'StDev'} {@nanstd_bc} {'StDev'};...
    {'Variance'} {@nanvar_bc} {'Variance'};...
    {'PctMissing'} {@(x)100*nnz(isnan(x))/numel(x)} {'PctMissing'};...
];

% Store names as variables in case I decide to change them
computeStatsPerTrial = 'Compute stats per trial';
computeStatOfAverage = 'Compute stat of trial average';
trialwiseOptions = {
    computeStatsPerTrial
    computeStatOfAverage
};

p = inputParser;
addParameter(p, 'statsStruct', []);
addParameter(p, 'trialwise', []);
addParameter(p, 'fullpath', []);
parse(p, varargin{:});

if isempty(p.Results.statsStruct)
    statsStruct = [];
    while true
        win = (inputdlg(...
            {sprintf('Define statistics window centred on trial-defining events\n\nWindow start:')
            'Window end:'}));
        if isempty(win)
            return
        end
        name = (inputdlg(...
            {'Name of window'}));
        if isempty(name)
            return
        else
            name = name{:};
        end
        sel = listdlg('PromptString', sprintf('Compute which statistics in window ''%s''?', name),...
            'ListString', statOptions(:, 1));
        if isempty(sel)
            return
        else
            stats = reshape(statOptions(sel, 1), 1, []);
        end
        statsStruct = [
            statsStruct...
            struct(...
                'name', name,...
                'win', {win},...
                'stats', {stats})
        ];
        q = 'Define another statistics window?';
        a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
        switch a
            case 'Yes'
                continue
            case 'No'
                break
            otherwise
                return
        end
    end
else
    statsStruct = p.Results.statsStruct;
end

if isempty(p.Results.trialwise)
    sel = listdlg('PromptString', 'How should individual trials be handled?',...
        'ListString', trialwiseOptions,...
        'SelectionMode', 'single');
    if isempty(sel)
        return
    else
        trialwise = trialwiseOptions{sel};
    end
else
    trialwise = p.Results.trialwise;
end

if isempty(p.Results.fullpath)
    [file, dir] = uiputfile('*.csv');
    if isnumeric(file)
        return
    end
    fullpath = sprintf('%s', dir, file);
else
    fullpath = p.Results.fullpath;
end

uniqueTrialSetNames = unique(mergefields(EYE, 'trialset', 'name'));
uniqueCondNames = unique(mergefields(EYE, 'cond'));

colNames = [{'Dataset' 'Cond'} strcat('Cond_', uniqueCondNames) strcat('TrialSet_', uniqueTrialSetNames)];
switch trialwise
    case computeStatsPerTrial
        newColNames = {'RT' 'Rejected' 'TrialIdx' 'TrialType'};
    otherwise
        newColNames = 'MeanRT';
end
colNames = [colNames newColNames];

statNames = [];
for ii = 1:numel(statsStruct)
    statNames = [statNames strcat(statsStruct(ii).name, '_', statsStruct(ii).stats)];
end

colNames = [colNames statNames];

statsTable = colNames;

fprintf('Computing statistics...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    % Get logical vector indicating experimental condition
    condVec = ismember(uniqueCondNames, EYE(dataidx).cond);
    switch trialwise % How to iterate through data?
        case computeStatsPerTrial % Iterate over epochs
            itermax = numel(EYE(dataidx).epoch);
        otherwise % Iterate over trial sets
            itermax = numel(uniqueTrialSetNames);
    end
    for iterator = 1:itermax
        for winidx = 1:numel(statsStruct)
            currwin = timestr2lat(EYE(dataidx), statsStruct(winidx).win);
            % Get data as vector, plus other columns of the new data table
            % row:
            switch trialwise
                case computeStatsPerTrial
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
            nStats = numel(statsStruct(winidx).stats);
            currStats = nan(1, nStats);
            for statidx = 1:nStats
                statname = statsStruct(winidx).stats{statidx};
                statoptidx = strcmp(statname, statOptions(:, 1));
                currStats(statidx) = feval(statOptions{statoptidx, 2}, data);
            end
            
            currRow = [
                EYE(dataidx).name... Dataset name
                condVec... Logical vector indicating experimental condition membership
                trialSetVec... Logical vector indicating trial set membership
                rtstat... Reaction time, either individual or trial set average
            ];
            switch trialwise
                case computeStatsPerTrial
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