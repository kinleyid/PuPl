function EYE = pupl_epoch(EYE, varargin)

%   Inputs

p = inputParser;
addParameter(p, 'timelocking', []);
addParameter(p, 'lims', []);
addParameter(p, 'overwrite', []);
parse(p, varargin{:});
unpack(p);

if any(arrayfun(@(x) ~isempty(x.epoch), EYE)) && isempty(overwrite)
    q = 'Overwrite existing trials?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
    switch a
        case 'Yes'
            overwrite = true;
        case 'No'
            overwrite = false;
        otherwise
            return
    end
end

if isempty(timelocking)
    eventTypes = unique(mergefields(EYE, 'event', 'type'));
    timelocking = eventTypes(listdlgregexp('PromptString', 'Epoch relative to which events?',...
        'ListString', eventTypes));
    if isempty(timelocking)
        return
    end
end

if isempty(lims)
    lims = (inputdlg(...
        {sprintf('Trials start at this time relative to events:')
        'Trials end at this time relative to events:'}));
    if isempty(lims)
        return
    else
        fprintf('Trials defined from [event] + [%s] to [event] + [%s]\n', lims{:})
    end
end

if overwrite
    [EYE.epoch] = deal([]);
end

fprintf('Extracting trial data...\n')
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    currlims = EYE(dataidx).srate*[parsetimestr(lims{1}, EYE(dataidx).srate) parsetimestr(lims{2}, EYE(dataidx).srate)];
    for eventType = reshape(timelocking, 1, [])
        for eventidx = find(strcmp({EYE(dataidx).event.type}, eventType))
            currEpoch = struct(...
                'reject', false,...
                'rellims', currlims,...
                'abslims', EYE(dataidx).event(eventidx).latency + currlims,...
                'name', EYE(dataidx).event(eventidx).type,...
                'event', EYE(dataidx).event(eventidx));
            EYE(dataidx).epoch = [EYE(dataidx).epoch, currEpoch];
        end
    end
    
    % Sort epochs by event time
    [~, I] = sort(mergefields(EYE(dataidx), 'epoch', 'event', 'latency'));
    EYE(dataidx).epoch = EYE(dataidx).epoch(I);
    
    % Set preliminary 1:1 trial set-to-trial relationship
    trialnames = unique({EYE(dataidx).epoch.name});
    trialsetdescriptions = struct(...
        'name', trialnames,...
        'members', cellfun(@cellstr, trialnames, 'UniformOutput', false));
    EYE(dataidx) = sub_createtrialsets(EYE(dataidx), trialsetdescriptions, true);
    
    EYE(dataidx).history{end + 1} = getcallstr(p);
    
    fprintf('%d trials extracted\n', numel(EYE(dataidx).epoch));
end
fprintf('Done\n');

end