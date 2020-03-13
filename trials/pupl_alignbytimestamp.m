
function out = pupl_alignbytimestamp(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    args = parseargs(varargin{:});
    event_idx = regexpsel({EYE.eventlog.event.type}, args.attach);
    event_times = [EYE.eventlog.event(event_idx).time] - EYE.t1;
    event_latencies = round(event_times * EYE.srate + 1);
    new_events = struct(...
        'type', {EYE.eventlog.event(event_idx).type},...
        'rt', {EYE.eventlog.event(event_idx).rt},...
        'time', num2cell(event_times),...
        'latency', num2cell(event_latencies));
    EYE.event = [EYE.event new_events];
    [~, I] = sort([EYE.event.latency]);
    EYE.event = EYE.event(I);
    out = EYE;
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'attach' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];

args = parseargs(varargin{:});

if isempty(args.attach)
    unique_types = unique(mergefields(EYE, 'eventlog', 'event', 'type'));
    sel = listdlgregexp(...
        'PromptString', 'Which events from the event log should be attached to the eye data?',...
        'ListString', unique_types,...
        'AllowRegexp', true);
    if isempty(sel)
        return
    else
        args.attach = unique_types(sel);
    end
end

outargs = args;

end