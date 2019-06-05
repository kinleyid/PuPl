function plottrialaverages(EYE, varargin)

p = inputParser;
addParameter(p, 'dataIdx', []);
addParameter(p, 'bin', []);
addParameter(p, 'errorBars', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end
    
if any(arrayfun(@(x) isempty(x.bin), EYE))
    uiwait(msgbox('Organize trials into sets first'));
    return
end

if ~isfield(mergefields(EYE, 'bin', 'data'), 'both')
    uiwait(msgbox('Merge the left and right streams before plotting'));
    return
end

f = figure('Visible', 'off'); hold on
xlabel('Time (s)');
ylabel('Pupil diameter');
legendentries = [];

while true
    if isempty(p.Results.dataIdx)
        dataIdx = listdlg('PromptString', 'Plot from which dataset?',...
            'ListString', {EYE.name},...
            'SelectionMode', 'single');
        if isempty(dataIdx)
            return
        end
    else
        dataIdx = p.Results.dataIdx;
    end

    if isempty(p.Results.bin)
        binNames = unique(mergefields(EYE, 'bin', 'name'));
        bin = binNames{listdlg('PromptString', 'Plot from which trial set?',...
            'ListString', binNames,...
            'SelectionMode', 'single')};
        if isempty(bin)
            return
        end
    else
        bin = p.Results.bin;
    end
    
    legendentries = [legendentries {[EYE(dataIdx).name ' ' bin]}];
    
    currBin = EYE(dataIdx).bin(strcmp({EYE(dataIdx).bin.name}, bin));
    data = currBin.data.both;
    
    if ~isempty(currBin.relLatencies)
        x = currBin.relLatencies;
    else
        warning('Bin contains epochs in which the relative positions of the events are different\nX-axis will begin at 0 seconds');
        0:size(data, 2)-1;
    end
    t = x /EYE(dataIdx).srate;
    set(f, 'Visible', 'on');
    figure(f);
    currplot = plot(t, nanmean_bc(data));
    x = [t t(end:-1:1)];
    y = [nanmean_bc(data) + nanstd_bc(data) ./ sqrt(sum(~isnan(data)))...
         fliplr(nanmean_bc(data) - nanstd_bc(data) ./ sqrt(sum(~isnan(data))))];
    fill(x, y, currplot.Color,...
        'EdgeColor', currplot.Color,...
        'FaceAlpha', 0.1,...
        'EdgeAlpha', 0.5,...
        'HandleVisibility', 'off');
    xlim([t(1) t(end)]);
    legend(legendentries, 'Interpreter', 'none');
    q = 'Add more data to this plot?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        return
    end
end

end