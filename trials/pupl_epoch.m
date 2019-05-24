function EYE = pupl_epoch(EYE, varargin)

%   Inputs

p = inputParser;
addParameter(p, 'events', []);
addParameter(p, 'lims', []);
parse(p, varargin{:});

callStr = sprintf('eyeData = %s(eyeData, ', mfilename);

if any(arrayfun(@(x) ~isempty(x.epoch), EYE))
    q = 'Overwrite existing trials?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
    switch a
        case 'Yes'
            [EYE.epoch] = deal([]);
        case 'No'
        otherwise
            return
    end
end

if isempty(p.Results.events)
    eventTypes = unique(mergefields(EYE, 'event', 'type'));
    events = eventTypes(listdlgregexp('PromptString', 'Epoch relative to which events?',...
        'ListString', eventTypes));
    if isempty(events)
        return
    end
else
    events = p.Results.events;
end
callStr = sprintf('%s''events'', %s, ', callStr, all2str(events));

if isempty(p.Results.lims)
    lims = (inputdlg(...
        {sprintf('Trials start at this time relative to events:')
        'Trials end at this time relative to events:'}));
    if isempty(lims)
        return
    else
        fprintf('Trials defined from [event] + [%s] to [event] + [%s]\n', lims{:})
    end
else
    lims = p.Results.lims;
end
callStr = sprintf('%s''lims'', %s)', callStr, all2str(lims));

fprintf('Extracting trial data...\n')
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    currEvents = {EYE(dataidx).event.type};
    currLims = EYE(dataidx).srate*[parsetimestr(lims{1}, EYE(dataidx).srate) parsetimestr(lims{2}, EYE(dataidx).srate)];
    relLatencies = currLims(1):currLims(2);
    for eventType = reshape(events, 1, [])
        for eventidx = find(strcmp(currEvents, eventType))
            currEpoch = struct(...
                'reject', false,...
                'relLatencies', relLatencies,...
                'label', EYE(dataidx).event(eventidx).type,...
                'eventLat', EYE(dataidx).event(eventidx).latency);
            currEpoch.absLatencies = EYE(dataidx).event(eventidx).latency + relLatencies;
            for datatype = {'diam' 'gaze'}
                for stream = reshape(fieldnames(EYE(dataidx).(datatype{:})), 1, [])
                    currEpoch.(datatype{:}).(stream{:}) = EYE(dataidx).(datatype{:}).(stream{:})(currEpoch.absLatencies);
                end
            end
            EYE(dataidx).epoch = cat(1, EYE(dataidx).epoch, currEpoch);
        end
    end
    EYE(dataidx).history = [
        EYE(dataidx).history
        callStr
    ];
    fprintf('done\n')
end
fprintf('Done\n');

end