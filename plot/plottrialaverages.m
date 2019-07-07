function plottrialaverages(EYE, varargin)

p = inputParser;
addParameter(p, 'dataidx', []);
addParameter(p, 'set', []);
parse(p, varargin{:});

f = figure('Visible', 'off'); hold on;
xlabel('Time (s)');
ylabel('Pupil diameter');
legendentries = [];

while true
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
        binNames = unique(mergefields(EYE, 'trialset', 'name'));
        set = binNames{listdlg('PromptString', 'Plot from which trial set?',...
            'ListString', binNames,...
            'SelectionMode', 'single')};
        if isempty(set)
            return
        end
    else
        set = p.Results.set;
    end
    
    legendentries = [legendentries {[EYE(dataidx).name ' ' set]}];
    [data, isrej] = gettrialsetdatamatrix(EYE(dataidx), set);
    data = data(~isrej, :);
    setidx = strcmp({EYE(1).trialset.name}, set);
    relLatencies = EYE(1).trialset(setidx).relLatencies;
    if ~isempty(relLatencies)
        x = relLatencies;
    else
        warning('Trial set contains epochs in which the relative positions of the events are different\nX-axis will begin at 0 seconds');
        x = 0:size(data, 2)-1;
    end
    t = x /unique([EYE(dataidx).srate]);
    figure(f);
    currplot = plot(t, nanmean_bc(data));
    x = [t t(end:-1:1)];
    y = [nanmean_bc(data) + nanstd_bc(data) ./ sqrt(sum(~isnan(data)))...
         fliplr(nanmean_bc(data) - nanstd_bc(data) ./ sqrt(sum(~isnan(data))))];
    fill(x, y, get(currplot, 'Color'),...
        'EdgeColor', get(currplot, 'Color'),...
        'FaceAlpha', 0.1,...
        'EdgeAlpha', 0.1,...
        'HandleVisibility', 'off');
    xlim([t(1) t(end)]);
    legend(legendentries, 'Interpreter', 'none');
    q = 'Add more data to this plot?';
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

if isgraphics(gcbf)
    fprintf('Equivalent command: %s\n', getcallstr(p, false));
end

end