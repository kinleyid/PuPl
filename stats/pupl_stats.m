
function pupl_stats(EYE, varargin)

%   Inputs
% stat--'mean' or 'peak-to-peak difference'
% win--either a numeric vector of 2 latencies or a cell array of 2 time strings
% byTrial--true or false

statOptions = [ % Name presented to user, function, column name
    {'Mean'} {@nanmean_bc} {'MeanDiam'};...
    {'Peak-to-peak difference'} {@(x)(max(x) - min(x))} {'PeakToPeakDiff'};...
    {'Variance'} {@nanvar_bc} {'Variance'}
];

trialwiseOptions = {
    'Compute stats per trial'
    'Compute average of trial stats'
    'Compute stat of trial average'
};

p = inputParser;
addParameter(p, 'stats', []);
addParameter(p, 'win', []);
addParameter(p, 'trialwise', []);
addParameter(p, 'path', []);
parse(p, varargin{:});
callStr = sprintf('%s(', mfilename);

if isempty(p.Results.stats)
    sel = listdlg('PromptString', 'Compute which statistic?',...
        'ListString', statOptions(:, 1));
    if isempty(sel)
        return
    else
        stats = reshape(statOptions(sel, 1), 1, []);
    end
else
    stats = p.Results.stats;
end
callStr = sprintf('%s''stats'', %s, ', callStr, all2str(stats));

if isempty(p.Results.win)
    win = (inputdlg(...
                {sprintf('Stats window starts at this time relative to events:')
                'Stats window ends at this time relative to events:'}));
    if isempty(win)
        return
    end
else
    win = p.Results.win;
end
callStr = sprintf('%s''win'', %s, ', callStr, all2str(win));

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
callStr = sprintf('%s''trialwise'', %s, ', callStr, all2str(trialwise));

if isempty(p.Results.path)
    [file, dir] = uiputfile('*.csv');
    if isnumeric(file)
        return
    end
    fullpath = sprintf('%s', dir, file);
else
    fullpath = p.Results.path;
end
callStr = sprintf('%s''path'', %s)', callStr, all2str(fullpath));

statidx = reshape(find(ismember(statOptions(:, 1), stats)), 1, []);
colNames = {'Dataset' 'TrialSet'};
if strcmp(trialwise, 'Compute stats per trial')
    colNames = [colNames 'TrialType'];
end
colNames = [colNames 'rt' reshape(statOptions(statidx, 3), 1, [])];

statsTable = colNames;

fprintf('Computing statistics...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    if ~isnumeric(win)
        currwin = cellfun(@(x) parsetimestr(x, EYE(dataidx).srate), win);
    else
        currwin = win;
    end
    currwin = currwin(:)'*EYE(dataidx).srate; % Window in latencies
    for setidx = 1:numel(EYE(dataidx).trialset)
        relLats = EYE(dataidx).trialset(setidx).relLatencies;
        if isempty(relLats)
            warning('You have combined epochs into a bin that do not all begin and end at the same time relative to their events');
            relLats = 0:size(bin.data.left, 2) - 1;
        end
        latidx = find(relLats == currwin(1)):find(relLats == currwin(2));
        
        data = gettrialsetdatamatrix(EYE(dataidx), setidx);
        data = data(:, latidx);
        if strcmp(trialwise, 'Compute stat of trial average')
            nRows = 1;
            data = nanmean_bc(data);
        else
            nRows = size(data, 1);
        end
        
        currStats = nan(nRows, numel(statidx));
        
        for rowidx = 1:nRows
            for currstatidx = statidx
                currStats(rowidx, currstatidx) = feval(statOptions{currstatidx, 2}, data(rowidx, :));
            end
        end
        
        if strcmp(trialwise, 'Compute average of trial stats')
            currStats = num2cell(nanmean_bc(currStats));
        end
        if strcmp(trialwise, 'Compute stats per trial')
            statsTable = [
                statsTable
                [
                    cellstr(repmat(EYE(dataidx).name, nRows, 1))...
                    cellstr(repmat(EYE(dataidx).trialset(setidx).name, nRows, 1))...
                    cellstr(reshape({EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx).name}, [], 1))... repmat(EYE(dataidx).trialset(binidx).name, nRows, 1))...
                    num2cell(reshape(mergefields(EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx), 'event', 'rt'), [], 1))...
                    num2cell(currStats)
                ];
            ];
        else
            statsTable = [
                statsTable
                [
                    cellstr(EYE(dataidx).name)...
                    cellstr(EYE(dataidx).trialset(setidx).name)...
                    nanmean_bc(mergefields(EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx), 'event', 'rt'))...
                    currStats
                ];
            ];
        end
    end
    fprintf('done\n');
end

if ~isempty(gcbf)
    fprintf('Equivalent command: %s\n', callStr);
end

fprintf('Writing to table...\n');
writecell(fullpath, statsTable, ',');
fprintf('Done\n');

end