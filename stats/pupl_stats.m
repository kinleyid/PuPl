
function pupl_stats(EYE, varargin)

%   Inputs
% stat--'mean' or 'peak-to-peak difference'
% win--either a numeric vector of 2 latencies or a cell array of 2 time strings
% byTrial--true or false

statOptions = {
    'Mean'
    'Peak-to-peak difference'
    'Variance'
};

trialwiseOptions = {
    'Compute stats per trial'
    'Compute average of trial stats'
    'Compute stat of trial average'
};

p = inputParser;
addParameter(p, 'stat', []);
addParameter(p, 'win', []);
addParameter(p, 'trialwise', []);
addParameter(p, 'path', []);
parse(p, varargin{:});
callStr = sprintf('%s(', mfilename);

if isempty(p.Results.stat)
    sel = listdlg('PromptString', 'Compute which statistic?',...
        'ListString', statOptions,...
        'SelectionMode', 'single');
    if isempty(sel)
        return
    else
        stat = statOptions{sel};
    end
else
    stat = p.Results.stat;
end
callStr = sprintf('%s''stat'', %s, ', callStr, all2str(stat));

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
callStr = sprintf('%s''trialwise'', %s)', callStr, all2str(trialwise));

statsTable = table;
columnNames = {'Dataset' 'TrialType'};

switch lower(stat)
    case 'mean'
        statcompfun = @mean;
        columnNames = [columnNames 'MeanDiam'];
    case 'peak-to-peak difference'
        statcompfun = @(x) max(x) - min(x);
        columnNames = [columnNames 'PeakToPeakDiff'];
    case 'variance'
        statcompfun = @(x) nanvar_bc(x);
        columnNames = [columnNames 'PeakToPeakDiff'];
end

for dataidx = 1:numel(EYE)
    if ~isnumeric(win)
        currwin = cellfun(@(x) parsetimestr(x, EYE(dataidx).srate), win);
    else
        currwin = win;
    end
    currwin = currwin(:)'*EYE(dataidx).srate; % Window in latencies
    for binidx = 1:numel(EYE(dataidx).bin)
        relLats = EYE(dataidx).bin(binidx).relLatencies;
        if isempty(relLats)
            warning('You have combined epochs into a bin that do not all begin and end at the same time relative to their events');
            relLats = 0:size(bin.data.left, 2) - 1;
        end
        latidx = find(relLats == currwin(1)):find(relLats == currwin(2));
        if strcmp(trialwise, 'Compute stat of trial average')
            nRows = 1;
            data = nanmean_bc(EYE(dataidx).bin(binidx).data.both(:, latidx));
        else
            nRows = size(EYE(dataidx).bin(binidx).data.both, 1);
            data = EYE(dataidx).bin(binidx).data.both(:, latidx);
        end
        currStats = nan(nRows, 1);
        for rowidx = 1:nRows
            currStats(rowidx) = feval(statcompfun, data(rowidx, :));
        end
        if strcmp(trialwise, 'Compute average of trial stats')
            currStats = nanmean_bc(currStats);
        end
        if strcmp(trialwise, 'Compute stats per trial')
            newTable = table(...
                cellstr(repmat(EYE(dataidx).name, nRows, 1)),...
                cellstr(repmat(EYE(dataidx).bin(binidx).name, nRows, 1)),...
                (1:nRows)',...
                currStats(:),...
                'VariableNames', [columnNames(1:end-1) 'TrialN' columnNames(end)]);
        else
            newTable = table(...
                cellstr(EYE(dataidx).name),...
                cellstr(EYE(dataidx).bin(binidx).name),...
                nanmean_bc(currStats),...
                'VariableNames', columnNames);
        end
        statsTable = cat(1, statsTable, newTable);
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
end

if isempty(p.Results.path)
    [file, dir] = uiputfile('*');
    path = sprintf('%s', dir, file);
else
    path = p.Results.path;
end
writetable(statsTable, path);

end