
function EYE = computereactiontimes(EYE, varargin)

p = inputParser;
addParameter(p, 'onsets', []);
addParameter(p, 'responses', []);
addParameter(p, 'writeto', []);
parse(p, varargin{:})

if isempty(p.Results.onsets)
    [~, onsets] = listdlgregexp(...
        'PromptString', 'Which events mark the onset of a trial?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')));
    if isempty(onsets)
        return
    end
else
    onsets = p.Results.onsets;
end

if isempty(p.Results.responses)
    [~, responses] = listdlgregexp(...
        'PromptString', 'Which events mark a response?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')));
    if isempty(responses)
        return
    end
else
    responses = p.Results.responses;
end

if isempty(p.Results.writeto)
    [~, events] = listdlgregexp(...
        'PromptString', 'Write RTs to which event(s)?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')));
    if isempty(events)
        return
    end
    win = inputdlg({...
        sprintf('Said events must occur within this window relative to trial onsets/responses\n\nWindow start')
        'Window end'});
    if isempty(win)
        return
    end
    q = 'Center windows on trial onsets or responses?';
    a = questdlg(q, q, 'Trial onsets', 'Responses', 'Cancel', 'Trial onsets');
    switch a
        case 'Trial onsets'
            centres = 'onsets';
        case 'Responses'
            centres = 'responses';
        otherwise
            return
    end
    writeto = struct(...
        'events', {cellstr(events)},...
        'win', {win},...
        'centres', centres);
else
    writeto = p.Results.writeto;
end

callstr = getcallstr(p);

fprintf('Computing reaction times...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    nresps = 0;
    nrts = [];
    curronsets = find(ismember({EYE(dataidx).event.type}, onsets));
    currresponses = find(ismember({EYE(dataidx).event.type}, responses));
    currwritetoevents = ismember({EYE(dataidx).event.type}, writeto.events);
    responsetimes = [EYE(dataidx).event(currresponses).time];
    for onsetidx = 1:numel(curronsets)
        responseidx = responsetimes >= EYE(dataidx).event(curronsets(onsetidx)).time;
        if onsetidx < numel(curronsets)
            responseidx = responseidx & ...
                responsetimes < EYE(dataidx).event(curronsets(onsetidx + 1)).time;
        end
        responseidx = find(responseidx, 1);
        if isempty(responseidx)
            rt = nan;
        else
            rt = EYE(dataidx).event(currresponses(responseidx)).time - ...
                EYE(dataidx).event(curronsets(onsetidx)).time;
            nresps = nresps + 1;
        end
        switch writeto.centres
            case 'onsets'
                centreidx = curronsets(onsetidx);
            case 'responses'
                centreidx = currresponses(responseidx);
        end
        currlats = timestr2lat(EYE(dataidx), writeto.win) + EYE(dataidx).event(centreidx).latency;
        currwritetoidx = currwritetoevents &...
            [EYE(dataidx).event.latency] >= currlats(1) &...
            [EYE(dataidx).event.latency] <= currlats(2);
        [EYE(dataidx).event(currwritetoidx).rt] = deal(rt);
        nrts(end + 1) = nnz(currwritetoidx);
    end
    fprintf('%d/%d trials have responses, %f RT(s) recorded per trial\n', nresps, numel(curronsets), mean(nrts));
    EYE(dataidx).history{end+1} = callstr;
end
fprintf('Done\n');

end