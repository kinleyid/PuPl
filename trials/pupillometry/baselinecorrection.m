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

if isempty(p.Results.event) || isempty(p.Results.lims)
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
            event = [];
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
end
callStr = sprintf('%s''event'', %s, ''lims'', %s)', callStr, all2str(event), all2str(lims));

for dataidx = 1:numel(EYE)
    fprintf('Baseline correcting %s using method %s...', EYE(dataidx).name, correctionType);
    currLims = EYE(dataidx).srate*[parsetimestr(lims{1}, EYE(dataidx).srate) parsetimestr(lims{2}, EYE(dataidx).srate)];
    if isempty(event) % Baselines defined relative to each epoch-defining event
        for epochidx = 1:numel(EYE(dataidx).epoch)
            baselineLats = EYE(dataidx).epoch(epochidx).eventLat + currLims;
            for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
                EYE(dataidx).epoch(epochidx).diam.(stream{:}) = correctionfunc(...
                    EYE(dataidx).epoch(epochidx).diam.(stream{:}),... trialvec
                    EYE(dataidx).diam.(stream{:})(baselineLats),... basevec
                    correctionType);
            end
        end
    else % Baselines defined relative to their own events
        epochlats = [EYE(dataidx).epoch.eventLat]; % Central latencies for epochs
        switch mapping{:}
            case 'one:all'
                baselineEventLats = [EYE(dataidx).event(...
                    find(ismember({EYE(dataidx).event.type}, event), 1)).eventLat]; % Central latencies for baselines
            case 'one:some'
                baselineEventLats = [EYE(dataidx).event(...
                    ismember({EYE(dataidx).event.type}, event)).eventLat]; % Central latencies for baselines
        end
        for baselineidx = 1:numel(baselineEventLats)
            baselineLats = baselineEventLats(baselineidx) + currLims;
            if baselineidx == 1 && any(epochlats < baselineEventLats(baselineidx))
                error('Some epochs occur before the first baseline period')
            end
            if baselineidx == numel(baselineEventLats)
                epochsToCorrectIdx = find(epochlats >= baselineEventLats(baselineidx));
            else
                epochsToCorrectIdx = find(...
                    epochlats > baselineEventLats(baselineidx) &...
                    epochlats < baselineEventLats(baselineidx + 1));
            end
            for epochidx = 1:numel(epochsToCorrectIdx)
                for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
                EYE(dataidx).epoch(epochidx).diam.(stream{:}) = correctionfunc(...
                    EYE(dataidx).epoch(epochidx).diam.(stream{:}),... trialvec
                    EYE(dataidx).diam.(stream{:})(baselineLats),... basevec
                    correctionType);
                end
            end
        end
    end
    EYE(dataidx).history = [EYE(dataidx).history
        callStr];
    fprintf('done\n');
end
fprintf('Done\n');

end

function outvec = correctionfunc(trialvec, basevec, correctionType)
    switch correctionType
        case 'subtract baseline mean'
            outvec = trialvec - mean(basevec, 'omitnan');
        case 'percent change from baseline mean'
            basemean = mean(basevec, 'omitnan');
            outvec = 100 * (trialvec - basemean) / basemean;
    end
end