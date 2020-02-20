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
    args.lims = {'0' '0'};
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
        eventTypes = unique(mergefields(EYE, 'event', 'type'));
        switch args.mapping
            case 'one:one'
                args.event = 0;
            otherwise
                args.event = eventTypes(listdlgregexp('PromptString', 'Baselines are defined relative to which events?',...
                    'SelectionMode', 'single',...
                    'ListString', eventTypes));
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
    case 'change from baseline mean'
        correctionFunc = @(tv, bv) 100 * (tv - nanmean_bc(bv)) / nanmean_bc(bv);
        relstr = '% change from baseline mean';
    case 'none'
        correctionFunc = @(tv, bv) tv;
        relstr = [];
end

% At the end of this there will be 2 arrays a cell array called
% baseline_lims, each element of which will be a 2-element numeric vector
% with the time limits, in seconds, of a baseline period such that epoch(n)
% will be corrected using baseline period baselinelims{n}

curr_lims = parsetimestr(args.lims, EYE.srate); % Doubles, in seconds
epoch_times = mergefields(EYE.epoch, 'event', 'time'); % Event latencies for epochs
if isnumeric(args.event) % Baselines defined relative to each epoch-defining event
    baselinelims = bsxfun(@plus, epoch_times(:), curr_lims(:)');
    baselinelims = mat2cell(baselinelims, ones(size(baselinelims, 1), 1), 2);
else % Baselines defined relative to their own events (other than those that define epochs)
    baseline_times = [EYE.event(ismember({EYE.event.type}, args.event)).time];
    if strcmp(args.mapping, 'one:all')
        baseline_times = baseline_times(1);
    end
    % Figure out which epochs occur after which baseline period
    baselinelims = {};
    for baselineidx = 1:numel(baseline_times)
        curr_baselinelims = baseline_times(baselineidx) + curr_lims;
        if baselineidx == 1 % Ensure no epochs are missed
            early_epoch_idx = epoch_times < baseline_times(baselineidx);
            if any(early_epoch_idx)
                error_txt = [
                    'The following epochs occur before the first baseline period:\n'...
                    sprintf('\t%s\n', EYE.epoch(early_epoch_idx).name)
                ];
                error(error_txt)
            end
        end
        % Correct all epochs whose defining events occur after the defining
        % event of the baseline period
        curr_epochstocorrect = epoch_times >= baseline_times(baselineidx);
        if baselineidx < numel(baseline_times)
            % But don't correct the epochs that occur after the next
            % baseline period
            curr_epochstocorrect = curr_epochstocorrect & ...
                epoch_times < baseline_times(baselineidx + 1);
        end
        baselinelims = [
            baselinelims
            repmat({curr_baselinelims}, nnz(curr_epochstocorrect), 1)
        ];
    end
end

for epochidx = 1:numel(EYE.epoch)
    EYE.epoch(epochidx).baseline = struct(...
        'lims', baselinelims{epochidx},...
        'func', correctionFunc);
end

if ~isempty(relstr)
    EYE.units.epoch{end} = relstr;
end

end