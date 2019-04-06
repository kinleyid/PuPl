
function pupl_stats(EYE, varargin)

%   Inputs
% stat--'mean' or 'peak-to-peak difference'
% win--either a numeric vector of 2 latencies or a cell array of 2 time strings
% byTrial--true or false

statOptions = {
    'Mean'
    'Peak-to-peak difference'
};

p = inputParser;
addParameter(p, 'stat', []);
addParameter(p, 'win', []);
addParameter(p, 'byTrial', []);
parse(p, varargin{:});

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

if isempty(p.Results.byTrial)
    q = 'Average over trials?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    switch a
        case 'Yes'
            byTrial = false;
        case 'No'
            byTrial = true;
    end
else
    byTrial = p.Results.byTrial;
end

statsTable = table;
columnNames = {'Dataset' 'TrialType'};

switch lower(stat)
    case 'mean'
        statcompfun = @mean;
        columnNames = [columnNames 'MeanDiam'];
    case 'peak-to-peak difference'
        statcompfun = @(x) max(x) - min(x);
        columnNames = [columnNames 'PeakToPeakDiff'];
end

if byTrial
    columnNames = [columnNames(1:2) 'TrialN' columnNames(end)];
end

for dataIdx = 1:numel(EYE)
    if ~isnumeric(win)
        currwin = cellfun(@(x) parsetimestr(x, EYE(dataIdx).srate), win);
    end
    for binIdx = 1:numel(EYE(dataIdx).bin)
        nRows = size(EYE(dataIdx).bin(binIdx).data.both, 1);
        currStats = nan(nRows, 1);
        for rowIdx = 1:nRows
            currStats(rowIdx) = feval(statcompfun, EYE(dataIdx).bin(binIdx).data.both(rowIdx, :));
        end
        if byTrial
            newTable = table(...
                repmat(EYE(dataIdx).name, nRows, 1),...
                repmat(EYE(dataIdx).bin(binIdx).name, nRows, 1),...
                (1:nRows)',...
                currStats(:),...
                'VariableNames', columnNames);
        else
            newTable = table(...
                EYE(dataIdx).name,...
                EYE(dataIdx).bin(binIdx).name,...
                mean(currStats, 'omitnan'),...
                'VariableNames', columnNames);
        end
        statsTable = [
            statsTable
            newTable
        ];
    end
end

end