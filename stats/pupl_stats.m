
function pupl_stats(EYE, varargin)

%   Inputs
% stat--
% win--either a numeric vector of 2 latencies or a cell array of 2 time strings
% byTrial--true or false

statOptions = [
%   {Name presented to user} {function} {column name in stats spreadsheet}
    {'Mean'} {@nanmean_bc} {'MeanDiam'};...
    {'Max'} {@max} {'Max'};...
    {'Min'} {@min} {'Min'};...
    {'Median'} {@nanmedian_bc} {'Median'};...
    {'PeakToPeakDifference'} {@(x)(max(x) - min(x))} {'PeakToPeakDiff'};...
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

colNames = {'Dataset' 'Cond' 'TrialSet'};
if strcmp(trialwise, computeStatsPerTrial)
    colNames = [colNames 'TrialType' 'TrialIdx' 'Rejected' 'RT'];
else
    colNames = [colNames 'MeanRT'];
end

statNames = [];
for ii = 1:numel(statsStruct)
    statNames = [statNames strcat(statsStruct(ii).name, '_', statsStruct(ii).stats)];
end

colNames = [colNames statNames];

statsTable = colNames;

fprintf('Computing statistics...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    for setidx = 1:numel(EYE(dataidx).trialset)
        stats = [];
        for statidx = 1:numel(statsStruct)
            currwin = timestr2lat(EYE(dataidx), statsStruct(statidx).win);
            relLats = EYE(dataidx).trialset(setidx).relLatencies;
            if isempty(relLats)
                warning('You have combined epochs into a bin that do not all begin and end at the same time relative to their events');
                relLats = 10; % Known bug
            end
            latidx = find(relLats == currwin(1)):find(relLats == currwin(2));
        
            [data, isrej] = gettrialsetdatamatrix(EYE(dataidx), EYE(dataidx).trialset(setidx).name);
            data = data(:, latidx);
            if strcmp(trialwise, computeStatOfAverage)
                nRows = 1;
                data = nanmean_bc(data(~isrej, :));
            else
                nRows = size(data, 1);
            end
            
            nStats = numel(statsStruct(statidx).stats);
            currStats = nan(nRows, nStats);
        
            for rowidx = 1:nRows
                for currstatidx = 1:nStats
                    statname = statsStruct(statidx).stats{currstatidx};
                    statoptidx = strcmp(statname, statOptions(:, 1));
                    currStats(rowidx, currstatidx) = feval(statOptions{statoptidx, 2}, data(rowidx, :));
                end
            end
            % Append to statistics portion of table horizontally
            stats = [stats currStats];
        end
        
        % Combine multiple conditions into a single string
        currCond = cellstr(EYE(dataidx).cond);
        currCond = cellstr(strcat(currCond{:}));
        
        % Append to stats table vertically
        switch trialwise
            case computeStatsPerTrial
                currTable = [
                    cellstr(repmat(EYE(dataidx).name, nRows, 1))... Dataset name
                    cellstr(repmat(currCond, nRows, 1))... Condition
                    cellstr(repmat(EYE(dataidx).trialset(setidx).name, nRows, 1))... Trial set name
                    cellstr(reshape({EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx).name}, [], 1))... Trial name
                    num2cell(reshape(EYE(dataidx).trialset(setidx).epochidx, [], 1)),... Trial index
                    num2cell(reshape([EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx).reject], [], 1))... Rejected?
                    num2cell(reshape(mergefields(EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx), 'event', 'rt'), [], 1))... Reaction time
                    num2cell(stats)
                ];
            case computeStatOfAverage
                currTable = [
                    cellstr(EYE(dataidx).name)... Recording name
                    currCond... Condition
                    cellstr(EYE(dataidx).trialset(setidx).name)... Trial set name
                    nanmean_bc(mergefields(EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx), 'event', 'rt'))... Mean reaction time
                    stats
                ];
        end
        statsTable = [
            statsTable
            currTable
        ];
    end
    fprintf('done\n');
end

fprintf('Writing to table...\n');
writecell(fullpath, statsTable, ',');
fprintf('Done\n');

if ~isempty(gcbf)
    fprintf('Equivalent command: %s\n', getcallstr(p, false));
end

end