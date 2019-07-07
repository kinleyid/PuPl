function eyeheatmap(EYE, varargin)

p = inputParser;
addParameter(p, 'dataidx', []);
addParameter(p, 'set', []);
addParameter(p, 'byRT', false);
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

[data, isrej] = gettrialsetdatamatrix(EYE(dataidx), set);
data = data(~isrej, :);

if p.Results.byRT
    setidx = strcmp({EYE(dataidx).trialset.name}, set);
    [~, I] = sort([EYE(dataidx).epoch(EYE(dataidx).trialset(setidx).epochidx).rt]);
    data = data(I, :);
    xlab = 'RT rank (fastest to slowest)';
else
    xlab = 'Trial';
end
byRT = p.Results.byRT;

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