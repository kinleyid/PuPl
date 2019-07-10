function EYE = baselinecorrection(EYE, varargin)

%   Inputs
% correctionType: 'subtract mean' or 'percent change'
% baselineDefs: struct with fields:
%       event: event name defining baseline
%       lims: lims around events
%       
%   Outputs
% EYE: struct array

p = inputParser;
addParameter(p, 'correctionType', []);
addParameter(p, 'event', []);
addParameter(p, 'lims', []);
addParameter(p, 'mapping', []);
parse(p, varargin{:});

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);

correctionOptions = {'subtract baseline mean'
    'percent change from baseline mean'};
if isempty(p.Results.correctionType)
    correctionType = correctionOptions(...
        listdlg('PromptString', 'Baseline correction type',...
        'ListString', correctionOptions));
    if isempty(correctionType)
        return
    end
    correctionType = correctionType{:};
else
    correctionType = p.Results.correctionType;
end
callStr = sprintf('%s''correctionType'', %s, ', callStr, all2str(correctionType));

if isempty(p.Results.event) || isempty(p.Results.lims) || isempty(p.Results.mapping)
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
else
    event = p.Results.event;
    lims = p.Results.lims;
    mapping = p.Results.mapping;
end
callStr = sprintf('%s''event'', %s, ''lims'', %s, ''mapping'', %s)', callStr, all2str(event), all2str(lims), all2str(mapping));

switch correctionType
    case 'subtract baseline mean'
        correctionFunc = @(tv, bv) tv - nanmean_bc(bv);
    case 'percent change from baseline mean'
        correctionFunc = @(tv, bv) 100 * (tv - nanmean_bc(bv)) / nanmean_bc(bv);
end

fprintf('Baseline correcting using method %s...\n', correctionType);
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    
    currLims = timestr2lat(EYE(dataidx), lims);
    if isnumeric(event) % Baselines defined relative to each epoch-defining event
        baselineLats = num2cell(bsxfun(@plus, mergefields(EYE(dataidx), 'epoch', 'event', 'latency'), currLims(:)), 1);
        epochsToCorrect = 1:numel(EYE(dataidx).epoch);
    else % Baselines defined relative to their own events
        epochlats = [EYE(dataidx).epoch.eventLat]; % Event latencies for epochs
        baselineEventLats = [EYE(dataidx).event(...
            ismember({EYE(dataidx).event.type}, event)).eventLat];
        if strcmp(mapping, 'one:all')
            baselineEventLats = baselineEventLats(1);
        end
        % Figure out which baselines correspond to which epochs
        baselineLats = {};
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
            baselineLats = [
                baselineLats
                repmmat({currBaselineLats}, numel(currEpochsToCorrect), 1)
            ];
            epochsToCorrect = [epochsToCorrect currEpochsToCorrect];
        end
    end
    for correctionidx = 1:numel(epochsToCorrect)
        for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
            EYE(dataidx).epoch(epochsToCorrect(correctionidx)).diam.(stream{:}) = correctionfunc(...
                EYE(dataidx).epoch(epochsToCorrect(correctionidx)).diam.(stream{:}),... trialvec
                EYE(dataidx).diam.(stream{:})(...
                    baselineLats{correctionidx}(1):baselineLats{correctionidx}(2)),... basevec
                correctionType);
        end
        EYE(dataidx).epoch(epochsToCorrect(correctionidx)).baseline = struct(...
            'abslims', baselineLats{correctionidx},...
            'func', correctionFunc);
    end
    EYE(dataidx).history{end + 1} = callStr;
    fprintf('done\n');
end
fprintf('Done\n');

end

function outvec = correctionfunc(trialvec, basevec, correctionType)
    switch correctionType
        case 'subtract baseline mean'
            outvec = trialvec - nanmean_bc(basevec);
        case 'percent change from baseline mean'
            basemean = nanmean_bc(basevec);
            outvec = 100 * (trialvec - basemean) / basemean;
    end
end