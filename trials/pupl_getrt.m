
function out = pupl_getrt(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_getrt(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
	'onsets' []
    'responses' []
	'writeto' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.onsets)
    [~, args.onsets] = listdlgregexp(...
        'PromptString', 'Which events mark the onset of a trial?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')));
    if isempty(args.onsets)
        return
    end
end

if isempty(args.responses)
    [~, args.responses] = listdlgregexp(...
        'PromptString', 'Which events mark a response?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')));
    if isempty(args.responses)
        return
    end
end

if isempty(args.writeto)
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
    args.writeto = struct(...
        'events', {cellstr(events)},...
        'win', {win},...
        'centres', centres);
end

outargs = args;

end

function EYE = sub_getrt(EYE, varargin)

args = parseargs(varargin{:});

onsets = args.onsets;
responses = args.responses;
writeto = args.writeto;

nresps = 0;
nrts = [];
curronsets = find(ismember({EYE.event.type}, onsets));
currresponses = find(ismember({EYE.event.type}, responses));
currwritetoevents = ismember({EYE.event.type}, writeto.events);
responsetimes = [EYE.event(currresponses).time];
for onsetidx = 1:numel(curronsets)
    responseidx = responsetimes >= EYE.event(curronsets(onsetidx)).time;
    if onsetidx < numel(curronsets)
        responseidx = responseidx & ...
            responsetimes < EYE.event(curronsets(onsetidx + 1)).time;
    end
    responseidx = find(responseidx, 1);
    if isempty(responseidx)
        rt = nan;
    else
        rt = EYE.event(currresponses(responseidx)).time - ...
            EYE.event(curronsets(onsetidx)).time;
        nresps = nresps + 1;
    end
    switch writeto.centres
        case 'onsets'
            centreidx = curronsets(onsetidx);
        case 'responses'
            centreidx = currresponses(responseidx);
    end
    currlats = timestr2lat(EYE, writeto.win) + EYE.event(centreidx).latency;
    currwritetoidx = currwritetoevents &...
        [EYE.event.latency] >= currlats(1) &...
        [EYE.event.latency] <= currlats(2);
    [EYE.event(currwritetoidx).rt] = deal(rt);
    nrts(end + 1) = nnz(currwritetoidx);
end
fprintf('%d/%d trials have responses, %f RT(s) recorded per trial\n', nresps, numel(curronsets), mean(nrts));

end