function out = pupl_baseline(EYE, varargin)

%   Inputs
% correctionType: 'subtract mean' or 'percent change'
% baselineDefs: struct with fields:
%       event: event name defining baseline
%       lims: lims around events
%       
%   Outputs
% EYE: struct array

if nargin == 0
    out = @getargs;
else
    out = sub_baseline(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'correction' []
    'mapping' []
    'len' []
    'when' []
	'timelocking' []
	'lims' []
    'other' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.correction)
    correctionOptions = {
        'subtract baseline mean'
        'percent change from baseline mean'
        'z-score based on baseline statistics'
        'none'};
    correction = correctionOptions(...
        listdlg('PromptString', 'Baseline correction type',...
        'ListString', correctionOptions));
    if isempty(correction)
        return
    end
    args.correction = correction{:};
end

if strcmp(args.correction, 'none') % Any baseline correction?
    % If none, fill in defaults
    args.mapping = 'one:all';
    args.timelocking = EYE(1).event(1).name; % Should be 'beginning of recording'
    args.lims = {'1d' '1d'};
    args.other = [];
    args.other.event = args.timelocking;
    args.other.when = 'after';
else
    if isempty(args.mapping)
        mappingOptions = {
            'one:one'
            'one:all'
            'one:some'
        };
        args.mapping = mappingOptions(...
            listdlg('PromptString', sprintf('Baseline-to-trial mapping'),...
            'ListString', mappingOptions));
        if isempty(args.mapping)
            return
        else
            args.mapping = args.mapping{:};
        end
    end
    
    if strcmp(args.mapping, 'one:some')
        if isempty(args.when)
            q = 'Do baselines occur before or after epochs?';
            args.when = lower(questdlg(q, q, 'Before', 'After', 'Cancel', 'Before'));
            if isempty(args.when)
                return
            end
        end
    else
        args.when = 0; % Not applicable
    end
    
    if isempty(args.len)
        q = sprintf('Fixed or variable length baselines?');
        a = lower(questdlg(q, q, 'Fixed', 'Variable', 'Cancel', 'Fixed'));
        switch a
            case {'fixed' 'variable'}
                args.len = a;
            otherwise
                return
        end
    end

    if isempty(args.timelocking)
        switch args.mapping
            case 'one:one'
                args.timelocking = 0; % Not applicable
                switch args.len
                    case 'fixed'
                        args.other.event = 0;
                        args.other.when = 'after';
                    case 'variable'
                        rel2 = 'Do baselines begin before epoch timelocking events or end after epoch timelocking events?';
                        a = questdlg(rel2, rel2, 'Begin before', 'End after', 'Cancel', 'Begin before');
                        switch a
                            case 'End after'
                                args.other.when = 'after';
                                pick_next = 'ends';
                            case 'Begin before'
                                args.other.when = 'before';
                                pick_next = 'beginnings';
                            otherwise
                                return
                        end
                        args.other.event = pupl_event_UIget(...
                            [EYE.event],...
                            sprintf('Baseline %s are defined relative to which events?', pick_next));
                        if isempty(args.other.event)
                            return
                        end
                end
            otherwise
                switch args.len
                    case 'fixed'
                        args.timelocking = pupl_event_UIget(mergefields(EYE, 'event'), 'Baselines are defined relative to which events?');
                        if isempty(args.timelocking)
                            return
                        end
                        args.other.event = args.timelocking;
                        args.other.when = 'after';
                    case 'variable'
                        args.timelocking = pupl_event_UIget(mergefields(EYE, 'event'), 'Baseline beginnings are defined relative to which events?');
                        if isempty(args.timelocking)
                            return
                        end
                        args.other.event = pupl_event_UIget(mergefields(EYE, 'event'), 'Baseline ends are defined relative to which events?');
                        if isempty(args.other.event)
                            return
                        end
                        args.other.when = 'after';
                    otherwise
                        return
                end
        end
    end

    if isempty(args.lims)
        rel2 = cell(1, 2);
        switch args.mapping
            case 'one:one'
                rel2(1:2) = {'epoch timelocking events'};
                if strcmp(args.len, 'variable')
                    switch args.other.when
                        case 'before'
                            rel2{1} = 'the events that signal their beginnings';
                        case 'after'
                            rel2{2} = 'the events that signal their ends';
                    end
                end
            otherwise
                rel2{1} = 'the events that signal their beginnings';
                rel2{2} = 'the events that signal their ends';
        end
        args.lims = inputdlg({
            sprintf('Baselines start at this time relative to %s:', rel2{1})
            sprintf('Baselines end at this time relative to %s:', rel2{2})
        });
        if isempty(args.lims)
            return
        end
    end
end

outargs = args;

end

function EYE = sub_baseline(EYE, varargin)

args = parseargs(varargin{:});

% get functions that will perform baseline correction and the new string
% that will describe the correction
switch args.correction
    case 'subtract baseline mean'
        correctionFunc = @(tv, bv) tv - nanmean_bc(bv);
        relstr = 'change from baseline mean';
    case 'percent change from baseline mean'
        correctionFunc = @(tv, bv) 100 * (tv - nanmean_bc(bv)) / nanmean_bc(bv);
        relstr = '% change from baseline mean';
    case 'z-score based on baseline statistics'
        correctionFunc = @(tv, bv) 100 * (tv - nanmean_bc(bv)) / nanstd_bc(bv);
        relstr = {'z-scores' 'from baseline stats'};
    case 'none'
        correctionFunc = @(tv, bv) tv;
        relstr = EYE.units.pupil{3};
end

switch args.mapping
    case 'one:one'
        tl_evs = pupl_epoch_get(EYE, EYE.epoch, '_tl');
        baselines = epoch_(EYE, [tl_evs.uniqid], args.lims, args.other, 'baseline');
    case 'one:some'
        cand_baselines = epoch_(EYE, args.timelocking, args.lims, args.other, 'baseline');
        cand_baseline_times = pupl_epoch_get(EYE, cand_baselines, 'time');
        epoch_times = pupl_epoch_get(EYE, EYE.epoch, 'time');
        baselines = [];
        for epoch_idx = 1:numel(epoch_times)
            switch args.when
                case 'before'
                    % Find latest baseline prior to epoch
                    baseline_idx = find(cand_baseline_times <= epoch_times(epoch_idx), 1, 'last');
                case 'after'
                    % Find earliest baseline after epoch
                    baseline_idx = find(cand_baseline_times >= epoch_times(epoch_idx), 1);
            end
            if isempty(baseline_idx)
                epoch_ev = pupl_epoch_get(EYE, EYE.epoch, '_tl');
                error('No baseline occurs %s the epoch associated with event %s (%f s)',...
                    args.when,...
                    epoch_ev.name,...
                    epoch_ev.time);
            end
            baselines = [baselines cand_baselines(baseline_idx)];
        end
    case 'one:all'
        tl_idx = find(pupl_event_sel(EYE.event, args.timelocking));
        tl_idx = tl_idx(1);
        tl_ev = EYE.event(tl_idx);
        baseline = epoch_(EYE, tl_ev.uniqid, args.lims, args.other, 'baseline');
        baselines = repmat(baseline, 1, numel(EYE.epoch));
end

[baselines.func] = deal(correctionFunc);

baselines = num2cell(baselines);

[EYE.epoch.baseline] = deal(baselines{:});

if ~isempty(relstr)
    relstr = cellstr(relstr);
    EYE.units.epoch(end-(numel(relstr)-1):end) = relstr;
end

end