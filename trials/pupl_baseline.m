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
    'correctionType' []
	'event' []
	'lims' []
	'mapping' []
});

end

function outargs = getargs(EYE, varargin)

args = parseargs(varargin{:});

if isempty(args.correctionType)
    correctionOptions = {
        'subtract baseline mean'
        'percent change from baseline mean'
        'none'};
    correctionType = correctionOptions(...
        listdlg('PromptString', 'Baseline correction type',...
        'ListString', correctionOptions));
    if isempty(correctionType)
        return
    end
    args.correctionType = correctionType{:};
end

if isempty(args.event) || isempty(args.lims) || isempty(args.mapping)
    mappingOptions = {'one:one'
        'one:all'
        'one:some'};
    mapping = mappingOptions(...
        listdlg('PromptString', 'Baseline-to-trial mapping',...
        'ListString', mappingOptions));
    if isempty(mapping)
        return
    end
    switch mapping{:}
        case 'one:one'
            lims = (inputdlg(...
                {sprintf('Baselines start at this time relative to events that define trials:')
                'Baselines end at this time relative to events that define trials:'}));
            if isempty(lims)
                return
            end
            event = 0;
        case 'one:all'
            eventTypes = unique(mergefields(EYE, 'event', 'type'));
            event = eventTypes(listdlgregexp('PromptString', 'Baseline is defined relative to which event?',...
                'SelectionMode', 'single',...
                'ListString', eventTypes));
            lims = (inputdlg(...
                {sprintf('Baselines start at this time relative to event:')
                'Baselines end at this time relative to event:'}));
            if isempty(lims)
                return
            end
        case 'one:some'
            eventTypes = unique(mergefields(EYE, 'event', 'type'));
            event = eventTypes(listdlgregexp('PromptString', 'Baselines are defined relative to which events?',...
                'SelectionMode', 'single',...
                'ListString', eventTypes));
            if isempty(event)
                return
            end
            lims = (inputdlg(...
                {sprintf('Baselines start at this time relative to event:')
                'Baselines end at this time relative to event:'}));
            if isempty(lims)
                return
            end
    end
end
args.event = event;
args.lims = lims;
args.mapping = mapping;

outargs = args;

end

function EYE = sub_baseline(EYE, varargin)

args = parseargs(varargin{:});

correctionType = args.correctionType;
lims = args.lims;
event = args.event;
mapping = args.mapping;

switch correctionType
    case 'subtract baseline mean'
        correctionFunc = @(tv, bv) tv - nanmean_bc(bv);
        relstr = 'relative to baseline mean';
    case 'change from baseline mean'
        correctionFunc = @(tv, bv) 100 * (tv - nanmean_bc(bv)) / nanmean_bc(bv);
        relstr = '% change from baseline mean';
    case 'none'
        correctionFunc = @(tv, bv) tv;
        relstr = [];
end

currLims = parsetimestr(lims, EYE.srate, 'smp');
if isnumeric(event) % Baselines defined relative to each epoch-defining event
    baselinelims = num2cell(bsxfun(@plus, mergefields(EYE, 'epoch', 'event', 'latency'), currLims(:)), 1);
    epochsToCorrect = 1:numel(EYE.epoch);
else % Baselines defined relative to their own events
    epochlats = [EYE.epoch.eventLat]; % Event latencies for epochs
    baselineEventLats = [EYE.event(...
        ismember({EYE.event.type}, event)).eventLat];
    if strcmp(mapping, 'one:all')
        baselineEventLats = baselineEventLats(1);
    end
    % Figure out which baselines correspond to which epochs
    baselinelims = {};
    epochsToCorrect = [];
    for baselineidx = 1:numel(baselineEventLats)
        currBaselineLats = baselineEventLats(baselineidx) + currLims;
        if baselineidx == 1 && any(epochlats < baselineEventLats(baselineidx))
            error('Some epochs occur before the first baseline period')
        end
        currEpochsToCorrect = epochlats >= baselineEventLats(baselineidx);
        if baselineidx < numel(baselineEventLats)
            currEpochsToCorrect = currEpochsToCorrect & ...
                epochlats < baselineEventLats(baselineidx + 1);
        end
        currEpochsToCorrect = find(currEpochsToCorrect);
        baselinelims = [
            baselinelims
            repmmat({currBaselineLats}, numel(currEpochsToCorrect), 1)
        ];
        epochsToCorrect = [epochsToCorrect currEpochsToCorrect];
    end
end
for correctionidx = 1:numel(epochsToCorrect)
    EYE.epoch(epochsToCorrect(correctionidx)).baseline = struct(...
        'abslims', baselinelims{correctionidx},...
        'func', correctionFunc);
end

EYE.units.epoch{end} = relstr;

end