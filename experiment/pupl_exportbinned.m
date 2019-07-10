function pupl_exportbinned(EYE, varargin)

p = inputParser;
addParameter(p, 'bins', []);
addParameter(p, 'fullpath', []);
parse(p, varargin{:});

fields = {
    'start' 'Start'
    'width' 'Width'
    'step' 'Step size'
    'nbins' 'Number of bins (integer)'
};

if isempty(p.Results.bins)
    vals = inputdlg({sprintf('Define bins\n\n%s', fields{1, 2}), fields{2:end, 2}});
    if isempty(vals)
        return
    end
    bins = [];
    for ii = 1:size(fields, 1)
        bins.(fields{ii, 1}) = vals{ii};
    end
    bins.nbins = str2double(bins.nbins);
else
    bins = p.Results.bins;
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

allsteps = 0:bins.nbins-1;
colnames = {'Dataset' 'Cond' 'TrialSet' 'TrialType' 'TrialIdx' 'Rejected' 'RT'};
for ii = 1:numel(allsteps)
    colnames{end + 1} = sprintf('Bin%d', ii);
end

bigtable = colnames;

fprintf('Computing data...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    for setidx = 1:numel(EYE(dataidx).trialset)
        data = gettrialsetdatamatrix(EYE(dataidx), EYE(dataidx).trialset(setidx).name);
        nrow = size(data, 1);
        relLats = EYE(dataidx).trialset(setidx).relLatencies;
        start = timestr2lat(EYE(dataidx), bins.start);
        width = timestr2lat(EYE(dataidx), bins.width);
        step = timestr2lat(EYE(dataidx), bins.step);
        celldat = cell(size(data, 1), numel(allsteps));
        for stepn = allsteps
            currstart = start + step * stepn;
            currend = currstart + width;
            currwin = unfold(find(relLats == currstart), find(relLats == currend));
            celldat(:, stepn + 1) = num2cell(nanmean_bc(data(:, currwin), 2));
        end
        
        % Combine multiple conditions into a single string
        currCond = cellstr(EYE(dataidx).cond);
        currCond = cellstr(strcat(currCond{:}));
        
        % Append to stats table vertically
        currtable = [
            cellstr(repmat(EYE(dataidx).name, nrow, 1))... Dataset name
            cellstr(repmat(currCond, nrow, 1))... Condition
            cellstr(repmat(EYE(dataidx).trialset(setidx).name, nrow, 1))... Trial set name
            cellstr(reshape({EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx).name}, [], 1))... Trial name
            num2cell(reshape(EYE(dataidx).trialset(setidx).epochidx, [], 1)),... Trial index
            num2cell(reshape([EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx).reject], [], 1))... Rejected?
            num2cell(reshape(mergefields(EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx), 'event', 'rt'), [], 1))... Reaction time
            celldat
        ];
        bigtable = [
            bigtable
            currtable
        ];
    end
    fprintf('done\n');
end
fprintf('Done\n');

fprintf('Writing to %s...\n', fullpath);
writecell2delim(fullpath, bigtable, ',');
fprintf('Done\n');

if ~isempty(gcbf)
    fprintf('Equivalent command: %s\n', getcallstr(p, false));
end

end