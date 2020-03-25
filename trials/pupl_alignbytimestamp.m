
function out = pupl_alignbytimestamp(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_align(EYE, varargin{:});
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
    unique_types = unique(mergefields(EYE, 'eventlog', 'event', 'name'));
    [~, sel] = listdlgregexp(...
        'PromptString', 'Which events from the event log should be attached to the eye data?',...
        'ListString', unique_types,...
        'AllowRegexp', true);
    if isempty(sel)
        return
    else
        args.attach = sel;
    end
end

outargs = args;

end

function EYE = sub_align(EYE, varargin)

args = parseargs(varargin{:});

event_idx = regexpsel(mergefields(EYE, 'eventlog', 'event', 'name'), args.attach);

curr_events = EYE.event;
new_events = EYE.eventlog.event(event_idx);

% Add new uniqids
curr_ids = [curr_events.uniqid];
new_ids = 1:numel(new_events);
new_ids = num2cell(new_ids + max(curr_ids));
[new_events.uniqid] = new_ids{:};
% Append
[curr_events, new_events] = fieldconsistency(curr_events, new_events);
EYE.event = [curr_events(:)' new_events(:)'];
[~, I] = sort([EYE.event.time]);
EYE.event = EYE.event(I);

end