function pupl_plot_sets(EYE, varargin)

p = inputParser;
addParameter(p, 'plotstruct', [])
addParameter(p, 'grand', false)
parse(p, varargin{:});

grand = p.Results.grand;

f = figure(...
    'UserData', struct('legend', []),... % Legend entries
    'Visible', 'off');
hold on;

if isempty(p.Results.plotstruct)
    plotstruct = [];
    while true
        plotidx = numel(plotstruct) + 1;
        %% Select recording(s)
        if grand
            cond_opts = unique(mergefields(EYE, 'cond'));
            if numel(cond_opts) > 1
                [~, cond] = listdlgregexp('PromptString', 'Plot from which between-subjects condition?',...
                    'ListString', unique(mergefields(EYE, 'cond')));
                if isempty(cond)
                    return
                end
            else
                cond = cond_opts(1);
            end
            dataidx = find(arrayfun(@(x) any(ismember(x.cond, cond)), EYE));
        else
            dataidx = listdlgregexp('PromptString', 'Plot from which recording?',...
                'ListString', {EYE.name});
            if isempty(dataidx)
                return
            end
            cond = {};
        end
        plotstruct(plotidx).dataidx = dataidx;
        plotstruct(plotidx).cond = cond;
        %% Get epoch selector
        epoch_selector = [];
        % epoch type
        epoch_type_opts = cellstr(unique(mergefields(EYE(dataidx), 'epoch', 'name')));
        if numel(epoch_type_opts) > 1
            sel = listdlgregexp('PromptString', 'Plot which epoch type?',...
            'ListString', epoch_type_opts,...
            'SelectionMode', 'single',...
            'regexp', false);
            if isempty(sel)
                return
            end
            epoch_selector.type = epoch_type_opts{sel};
        else
            epoch_selector.type = epoch_type_opts{1};
        end
        % Select epoch set/condition
        set_opts = unique(mergefields(EYE(dataidx), 'epochset', 'name'));
        sel = listdlgregexp('PromptString', 'Plot from which epoch set?',...
            'ListString', set_opts,...
            'SelectionMode', 'single',...
            'regexp', false);
        if isempty(sel)
            return
        end
        epoch_selector.set = set_opts{sel};
        plotstruct(plotidx).selector = epoch_selector;
        %% Select rejection
        q = 'Plot which epochs?';
        a = questdlg(q, q, 'Unrejected', 'All', 'Rejected', 'Unrejected');
        if isempty(a)
            return
        end
        plotstruct(plotidx).include = lower(a);
        %% Select weighting
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
        %% Plot and loop
        set(f, 'Visible', 'on');
        applyplotargs(f, EYE, plotstruct(plotidx), grand);
        
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
    applyplotargs(f, EYE, plotstruct, grand);
end

if isgraphics(gcbf)
    fprintf('Equivalent command:\n\n%s\n\n', getcallstr(p, false));
end

end

function applyplotargs(f, EYE, plotstruct, grand)

figure(f);

all_epochs = {};
for plotidx = 1:numel(plotstruct)
    dataidx = plotstruct(plotidx).dataidx;
    curr_selector = plotstruct(plotidx).selector;
    curr_set = curr_selector.set;
    
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
    fprintf('Getting data ')
    printprog('setmax', numel(datasets));
    n = 0;
    for curr_idx = datasets(:)'
        n = n + 1;
        % Get data
        [data, isrej, lims, bef_aft, rel_lats] = pupl_epoch_getdata(EYE(curr_idx{:}), curr_selector);
        if isequal(rel_lats{:})
            all_rel_lats{end + 1} = rel_lats{1};
        else
            error('Inconsistent epoching in set %s: epochs don''t all begin and end at the same time relative to timelocking events in set', curr_set);
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
        % Get units
        all_epochs{end + 1} = pupl_epoch_get(EYE(curr_idx{:}), curr_selector);
        printprog(n);
    end
    % Check consistency
    all_bef_aft = cat(2, all_bef_aft{:});
    if isequal(all_bef_aft{:})
        bef_aft = all_bef_aft{1};
    else
        error('Inconsistent epoching in set %s: some epochs begin before timelocking events while others end after', curr_set)
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
            error('Inconsistent epoching in set %s: epochs don''t all begin and end at the same time relative to timelocking events in set', curr_set);
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
    nmu(nmu == 0) = 1;
    sem = nanstd_bc(alldata, 0, 1) ./ sqrt(nmu);
    
    % Get legend entries
    if grand
        names = plotstruct(plotidx).cond;
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
    plotstruct(plotidx).legendentry = sprintf('%s%s %s n = %d %s (plotting %s epochs)',...
        names, curr_set, curr_selector.type, ndata, unitofanalysis, plotstruct(plotidx).include);
    
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
    tmp_t = t;
    tmp_mu = mu;
    tmp_sem = sem;
    nan_indic = isnan(mu) | isnan(sem);
    s_idx = 1;
    while true
        e_idx = find(nan_indic(s_idx:end), 1) + s_idx - 1;
        if isempty(e_idx)
            e_idx = numel(nan_indic);
        end
        idx = s_idx:e_idx - 1;
        x = [tmp_t(idx) fliplr(tmp_t(idx))];
        y = [
            tmp_mu(idx) + tmp_sem(idx)...
            fliplr(tmp_mu(idx) - tmp_sem(idx))
        ];
        fill(x, y, get(currplot, 'Color'),...
            'EdgeColor', get(currplot, 'Color'),...
            'FaceAlpha', 0.1,...
            'EdgeAlpha', 0.0,...
            'HandleVisibility', 'off');
        s_idx = find(~nan_indic(e_idx:end), 1) + e_idx - 1;
        if isempty(s_idx) || s_idx == numel(nan_indic)
            break
        end
    end
    xlim([t(1) t(end)]);
end

xlabel('Time (s)');
ylabel(sprintf('Mean %s', lower(pupl_epoch_units([all_epochs{:}]))));

% Append to legend
ud = get(f, 'UserData');
ud.legend = [ud.legend {plotstruct.legendentry}];
legend(ud.legend{:}, 'Interpreter', 'none');
set(f, 'UserData', ud);

end