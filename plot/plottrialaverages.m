function plottrialaverages(EYE, varargin)

p = inputParser;
addParameter(p, 'plotstruct', [])
addParameter(p, 'bycond', false)
parse(p, varargin{:});

bycond = p.Results.bycond;

f = figure('Visible', 'off'); hold on;

if isempty(p.Results.plotstruct)
    plotstruct = [];
    while true
        plotidx = numel(plotstruct) + 1;
        if bycond
            [~, cond] = listdlgregexp('PromptString', 'Plot from which dataset?',...
                'ListString', unique(mergefields(EYE, 'cond')));
            if isempty(cond)
                return
            end
            dataidx = find(arrayfun(@(x) any(ismember(x.cond, cond)), EYE));
        else
            dataidx = listdlgregexp('PromptString', 'Plot from which dataset?',...
                'ListString', {EYE.name});
            if isempty(dataidx)
                return
            end
        end
        plotstruct(plotidx).dataidx = dataidx;
        
        setopts = unique(mergefields(EYE(dataidx), 'epochset', 'name'));
        sel = listdlg('PromptString', 'Plot from which trial set?',...
            'ListString', setopts,...
            'SelectionMode', 'single');
        if isempty(sel)
            return
        end
        set = setopts{sel};
        plotstruct(plotidx).set = set;
        
        q = 'Plot which trials?';
        a = questdlg(q, q, 'Unrejected', 'All', 'Rejected', 'Unrejected');
        if isempty(a)
            return
        end
        plotstruct(plotidx).include = lower(a);
        
        applyplotargs(f, EYE, plotstruct, bycond);
        
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
else
    plotstruct = p.Results.plotstruct;
    applyplotargs(f, EYE, plotstruct, bycond);
end

if isgraphics(gcbf)
    fprintf('Equivalent command: %s\n', getcallstr(p, false));
end

end

function applyplotargs(f, EYE, plotstruct, bycond)

figure(f);
clf; hold on;

for plotidx = 1:numel(plotstruct)
    dataidx = plotstruct(plotidx).dataidx;
    set = plotstruct(plotidx).set;
    
    [data, isrej] = pupl_epoch_getdata(EYE(dataidx), set);
    data = cell2mat(data);
    
    switch plotstruct(plotidx).include
        case 'all'
            isrej = false(size(isrej));
        case 'rejected'
            isrej = ~isrej;
    end
    
    if bycond
        names = unique(mergefields(EYE(dataidx), 'cond'));
    else
        names = {EYE(dataidx).name};
    end
    names = sprintf('%s &', names{:});
    names(end-numel(' &')+1:end) = [];
    plotstruct(plotidx).legendentry = sprintf('%s %s n = %d trials (showing %s trials)',...
        names, plotstruct(plotidx).set, nnz(~isrej), plotstruct(plotidx).include);
    
    data = data(~isrej, :);
    setidx = strcmp({EYE(1).epochset.name}, set);
    rellims = EYE(1).epochset(setidx).rellims;
    if ~isempty(rellims)
        x = unfold(rellims);
    else
        warning('Epoch set contains epochs in which the relative positions of the events are different\nX-axis will begin at 0 seconds');
        x = 0:size(data, 2)-1;
    end
    t = x /[EYE(dataidx).srate];
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
end

xlabel('Time (s)');
ylabel(sprintf('Mean pupil %s (%s, %s)', EYE(dataidx).units.epoch{:}));

legend(plotstruct.legendentry, 'Interpreter', 'none');

end