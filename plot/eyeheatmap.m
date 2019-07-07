function eyeheatmap(EYE, varargin)

p = inputParser;
addParameter(p, 'dataidx', []);
addParameter(p, 'set', []);
addParameter(p, 'byRT', []);
addParameter(p, 'include', []);
parse(p, varargin{:});

if isempty(p.Results.dataidx)
    dataidx = listdlg('PromptString', 'Plot from which dataset?',...
        'ListString', {EYE.name});
    if isempty(dataidx)
        return
    end
else
    dataidx = p.Results.dataidx;
end

if isempty(p.Results.set)
    % setNames = unique(mergefields(EYE, 'set', 'name'));
    setNames = unique(mergefields(EYE, 'trialset', 'name'));
    set = setNames{listdlg('PromptString', 'Plot from which trial set?',...
        'ListString', setNames,...
        'SelectionMode', 'single')};
    if isempty(set)
        return
    end
else
    set = p.Results.set;
end

if isempty(p.Results.byRT)
    q = 'Sort trials by reaction time?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
    switch a
        case 'Yes'
            byRT = true;
        case 'No'
            byRT = false;
        otherwise
            return
    end
else
    byRT = p.Results.byRT;
end

if isempty(p.Results.include)
    q = 'Plot which trials?';
    a = questdlg(q, q, 'Unrejected', 'All', 'Rejected', 'Unrejected');
    if isempty(a)
        return
    end
    include = lower(a);
else
    include = p.Results.include;
end

[data, isrej] = gettrialsetdatamatrix(EYE(dataidx), set);

switch include
    case 'all'
        isrej = false(size(isrej));
    case 'rejected'
        isrej = ~isrej;
end
data = data(~isrej, :);

if byRT
    setidx = strcmp({EYE(dataidx).trialset.name}, set);
    RTs = mergefields(EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx), 'event', 'rt');
    RTs = RTs(~isrej);
    [~, I] = sort(RTs);
    data = data(I, :);
    xlab = 'RT rank (fastest to slowest)';
else
    xlab = 'Trial';
end

latencies = 1:size(data, 2);
times = (latencies - 1)/unique([EYE(dataidx).srate]);
figure;
ii = image(times, 1:size(data, 1), data,'CDataMapping','scaled');
try
    set(ii, 'AlphaData', ~isnan(data));
catch
    '';
end
ylabel(xlab)
xlabel('Time (s)')
cb = colorbar;
ylabel(cb, 'Pupil diameter')
title([EYE(dataidx).name ' ' set], 'Interpreter', 'none');

if isgraphics(gcbf)
    fprintf('Equivalent command: %s\n', getcallstr(p, false));
end

end