function pupl_plot_sets_new(EYE, varargin)

p = inputParser;
addParameter(p, 'plotstruct', [])
addParameter(p, 'bycond', false)
parse(p, varargin{:});

bycond = p.Results.bycond;

f = figure(...
    'UserData', struct('legend', []),... % Legend entries
    'Visible', 'off');
hold on;

if isempty(p.Results.plotstruct)
    plotstruct = [];
    while true
        plotidx = numel(plotstruct) + 1;
        if bycond
            [~, cond] = listdlgregexp('PromptString', 'Plot from which condition?',...
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
        curr_set = setopts{sel};
        plotstruct(plotidx).set = curr_set;
        
        q = 'Plot which trials?';
        a = questdlg(q, q, 'Unrejected', 'All', 'Rejected', 'Unrejected');
        if isempty(a)
            return
        end
        plotstruct(plotidx).include = lower(a);
        
        if nnz(dataidx) > 1
            q = 'How should epochs be weighted?';
            a = questdlg(q, q, 'Weight by trial', 'Weight by participant', 'Cancel', 'Weight by trial');
            switch a
                case 'Weight by trial'
                    weight = 'trial';
                case 'Weight by participant'
                    weight = 'participant';
                otherwise
                    return
            end
            plotstruct(plotidx).weight = weight;
        else
            plotstruct(plotidx).weight = 'trial';
        end
        
        set(f, 'Visible', 'on');
        applyplotargs(f, EYE, plotstruct(plotidx), bycond);
        
        q = 'Add more data to this plot?';
        a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
        switch a
            case 'Yes'
                plotidx = plotidx + 1;
                continue
            otherwise
                break
        end
    end
else
    plotstruct = p.Results.plotstruct;
    applyplotargs(f, EYE, plotstruct, bycond);
end

if isgraphics(gcbf)
    fprintf('Equivalent command:\n%s\n', getcallstr(p, false));
end

end

function applyplotargs(f, EYE, plotstruct, bycond)

figure(f);

for plotidx = 1:numel(plotstruct)
    dataidx = plotstruct(plotidx).dataidx;
    currset = plotstruct(plotidx).set;
    
    switch plotstruct(plotidx).weight
        case 'trial'
            datasets = {dataidx};
        case 'participant'
            datasets = num2cell(dataidx);
    end
    
    alldata = {};
    ndata = 0;
    all_lims = {};
    all_bef_aft = {};
    all_rel_lats = {};
    for curr_idx = datasets(:)'
        [data, isrej, lims, bef_aft, rel_lats] = pupl_epoch_getdata_new(EYE(curr_idx{:}), currset);
        if isequal(rel_lats{:})
            all_rel_lats{end + 1} = rel_lats{1};
        else
            error('Inconsistent epoching in set %s: epochs don''t all begin and end at the same time relative to timelocking events in set', currset.name);
        end
        all_lims{end + 1} = lims;
        all_bef_aft{end + 1} = bef_aft;
        data = cell2mat(data);
        switch plotstruct(plotidx).include
            case 'all'
                isrej = false(size(isrej));
            case 'rejected'
                isrej = ~isrej;
        end
        data = data(~isrej, :);
        switch plotstruct(plotidx).weight
            case 'trial'
                alldata{end + 1} = data;
                ndata = ndata + size(data, 1);
            case 'participant'
                alldata{end + 1} = nanmean_bc(data, 1);
        end
    end
    % Check consistency
    all_bef_aft = cat(2, all_bef_aft{:});
    if isequal(all_bef_aft{:})
        bef_aft = all_bef_aft{1};
    else
        error('Inconsistent epoching in set %s: some epochs begin before timelocking events while others end after', currset.name)
    end
    % Ensure all data is of the same length
    lens = cellfun(@(x) size(x, 2), alldata);
    max_len = max(lens);
    too_short = find(lens(:)' < max_len);
    for dataidx = too_short
        n_missing = max_len - lens(dataidx);
        new_nans = nan(size(alldata{dataidx}, 1), n_missing);
        switch bef_aft
            case 'before'
                alldata{dataidx} = [new_nans alldata{dataidx}];
                all_rel_lats{dataidx}(1) = all_rel_lats{dataidx}(1) - n_missing;
            case 'after'
                alldata{dataidx} = [alldata{dataidx} new_nans];
                all_rel_lats{dataidx}(2) = all_rel_lats{dataidx}(2) + n_missing;
        end
    end
    if numel(all_rel_lats) > 1
        if isequal(all_rel_lats{:})
            rel_lats = all_rel_lats{1};
        else
            error('Inconsistent epoching in set %s: epochs don''t all begin and end at the same time relative to timelocking events in set', currset.name);
        end
    else
        rel_lats = all_rel_lats{:};
    end
    all_lims = cat(1, all_lims{:});
    alldata = cat(1, alldata{~cellfun(@isempty, alldata)});
    if strcmp(plotstruct(plotidx).weight, 'participant')
        ndata = size(alldata, 1);
    end
    mu = nanmean_bc(alldata, 1);
    nmu = sum(~isnan(alldata), 1);
    if nmu > 1
        sem = nanstd_bc(alldata, 0, 1) ./ sqrt(nmu);
    else
        sem = zeros(size(mu));
    end
    
    % Get legend entries
    if bycond
        names = unique(mergefields(EYE(dataidx), 'cond'));
    else
        names = {EYE(dataidx).name};
    end
    if isempty(names)
        names = '';
    else
        names = cellstr(names);
        names = sprintf('%s ', names{:});
    end
    switch plotstruct(plotidx).weight
        case 'participant'
            unitofanalysis = 'recordings';
        case 'trial'
            unitofanalysis = 'trials';
    end
    plotstruct(plotidx).legendentry = sprintf('%s%s n = %d %s (plotting %s trials)',...
        names, plotstruct(plotidx).set, ndata, unitofanalysis, plotstruct(plotidx).include);
    
    if numel(EYE) > 1
        if isequal(EYE.srate)
            srate = EYE(1).srate;
        else
            txt = {'Inconsistent sample rates:'};
            for ii = 1:numel(EYE)
                txt{end + 1} = sprintf('\t%s: %f Hz', EYE(ii).name, EYE(ii).srate);
            end
            error('%s\n', txt{:});
        end
    else
        srate = EYE.srate;
    end
    
    tlims = rel_lats / srate;
    t = linspace(tlims(1), tlims(2), numel(mu));
    currplot = plot(t, mu);
    x = [t t(end:-1:1)];
    y = [
        mu + sem...
        fliplr(mu - sem)
    ];
    fill(x, y, get(currplot, 'Color'),...
        'EdgeColor', get(currplot, 'Color'),...
        'FaceAlpha', 0.1,...
        'EdgeAlpha', 0.0,...
        'HandleVisibility', 'off');
    xlim([t(1) t(end)]);
end

xlabel('Time (s)');
ylabel(sprintf('Mean %s', lower(pupl_getunits(EYE, 'epoch'))));

% Append to legend
ud = get(f, 'UserData');
ud.legend = [ud.legend {plotstruct.legendentry}];
legend(ud.legend{:}, 'Interpreter', 'none');
set(f, 'UserData', ud);

end