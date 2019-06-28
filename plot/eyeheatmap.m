function eyeheatmap(EYE, varargin)

p = inputParser;
addParameter(p, 'dataIdx', []);
addParameter(p, 'set', []);
addParameter(p, 'byRT', false);
parse(p, varargin{:});

if isempty(p.Results.dataIdx)
    dataidx = listdlg('PromptString', 'Plot from which dataset?',...
        'ListString', {EYE.name},...
        'SelectionMode', 'single');
    if isempty(dataidx)
        return
    end
else
    dataidx = p.Results.dataIdx;
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

setidx = strcmp({EYE(dataidx).trialset.name}, set);
data = gettrialsetdatamatrix(EYE(dataidx), setidx);

if p.Results.byRT
    [~, I] = sort([EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx).rt]);
    data = data(I, :);
    xlab = 'RT rank (fastest to slowest)';
else
    xlab = 'Trial';
end

latencies = 1:size(data, 2);
times = (latencies - 1)/EYE(dataidx).srate;
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

end