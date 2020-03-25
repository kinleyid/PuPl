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
	'event' []
	'lims' []
	'mapping' []
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
    args.event = EYE(1).event(1).type; % Should be 'beginning of recording'
    args.lims = {'1d' '1d'};
else
    if isempty(args.mapping)
        mappingOptions = {'one:one'
            'one:all'
            'one:some'};
        args.mapping = mappingOptions(...
            listdlg('PromptString', 'Baseline-to-trial mapping',...
            'ListString', mappingOptions));
        if isempty(args.mapping)
            return
        else
            args.mapping = args.mapping{:};
        end
    end

    if isempty(args.event)
        switch args.mapping
            case 'one:one'
                args.event = 0;
            otherwise
                args.event = pupl_event_UIget(mergefields(EYE, 'event'), 'Baselines are defined relative to which events?');
                if isempty(args.event)
                    return
                end
        end
    end

    if isempty(args.lims)
        switch args.mapping
            case 'one:one'
                args.lims = (inputdlg(...
                    {sprintf('Baselines start at this time relative to events that define trials:')
                    'Baselines end at this time relative to events that define trials:'}));
                if isempty(args.lims)
                    return
                end
            otherwise
                args.lims = (inputdlg(...
                    {sprintf('Baselines start at this time relative to event:')
                    'Baselines end at this time relative to event:'}));
                if isempty(args.lims)
                    return
                end
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
        relstr = {'z-scores' 'based on baseline stats'};
    case 'none'
        correctionFunc = @(tv, bv) tv;
        relstr = EYE.units.pupil{3};
end

% At the end of this there will be an array called baseline_uniqids, such
% that epoch(n) will be corrected by a baseline period centered on the
% event with uniqid baseline_uniqids(n)

epoch_times = pupl_epoch_get(EYE, [], 'time'); % Latencies of epoch-defining events
if isnumeric(args.event) % Baselines defined relative to each epoch-defining event
    baseline_uniqids = [EYE.epoch.event]; % Uniqids
else % Baselines defined relative to their own events (other than those that define epochs)
    baseline_events = EYE.event(pupl_event_sel(EYE.event, args.event));
    if strcmp(args.mapping, 'one:all')
        baseline_events = baseline_events(1);
    end
    % Figure out which epochs occur after which baseline period
    baseline_uniqids = [];
    for baseline_idx = 1:numel(baseline_events)
        if baseline_idx == 1 % Ensure no epochs are missed
            early_epoch_idx = epoch_times < EYE.event(baseline_idx).time;
            if any(early_epoch_idx)
                error_txt = [
                    'The following epochs occur before the first baseline period:\n'...
                    sprintf('\t%s\n', pupl_epoch_get(EYE, early_epoch_idx, 'name'))
                ];
                error(error_txt) % This should probably just be a warning
            end
        end
        % Correct all epochs whose defining events occur after the defining
        % event of the baseline period
        correct_idx = epoch_times >= baseline_events(baseline_idx).time;
        if baseline_idx < numel(baseline_events)
            % But don't correct the epochs that occur after the next
            % baseline period
            correct_idx = correct_idx & ...
                epoch_times < baseline_events(baseline_idx + 1).time;
        end
        baseline_uniqids = [
            baseline_uniqids;
            repmat(baseline_events(baseline_idx).uniqid, nnz(correct_idx), 1)
        ];
    end
end

rel_lats = parsetimestr(args.lims, EYE.srate, 'smp');
event_ids = [EYE.event.uniqid];
for epochidx = 1:numel(EYE.epoch)
    abs_lats = rel_lats + pupl_event_getlat(EYE, baseline_uniqids(epochidx) == event_ids);
    if abs_lats(1) < 1
        error('Trying to create a baseline period starting at latency %d (earliest possible latency is 1)', baselinelims{epochidx}(1))
    end
    if abs_lats(2) > EYE.ndata
        error('Trying to create a baseline period ending at latency %d (earliest possible latency for this recording is %d)', baselinelims{epochidx}(2), EYE.ndata)
    end
    EYE.epoch(epochidx).baseline = struct(...
        'lims', {args.lims},...
        'event', baseline_uniqids(epochidx),...
        'func', correctionFunc);
end

if ~isempty(relstr)
    relstr = cellstr(relstr);
    EYE.units.epoch(end-(numel(relstr)-1):end) = relstr;
end

end