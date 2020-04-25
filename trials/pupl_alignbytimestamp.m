
function out = pupl_alignbytimestamp(EYE, varargin)
% Align eye tracker data and event logs by timestamps
%
% Inputs:
%   attach: cell array
%       selects the events to add from the event log (see pupl_event_sel)
%   overwrite: boolean
%       specifies whether eye tracker event data should be deleted
if nargin == 0
    out = @getargs;
else
    out = sub_align(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'attach' []
    'overwrite' []
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

if isempty(args.overwrite)
    q = 'Overwrite events already in eye data?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
    switch a
        case 'Yes'
            args.overwrite = true;
        case 'No'
            args.overwrite = false;
        otherwise
            return
    end
end

outargs = args;

end

function EYE = sub_align(EYE, varargin)

args = parseargs(varargin{:});

event_idx = regexpsel(mergefields(EYE, 'eventlog', 'event', 'name'), args.attach);

if args.overwrite
    EYE.event = [];
    max_uniqid = 0;
else
    max_uniqid = max([EYE.event.uniqid]);
end

curr_events = EYE.event;
new_events = EYE.eventlog.event(event_idx);

% Add new uniqids
new_ids = 1:numel(new_events);
new_ids = num2cell(new_ids + max_uniqid);
[new_events.uniqid] = new_ids{:};
% Append
[curr_events, new_events] = fieldconsistency(curr_events, new_events);
EYE.event = [curr_events(:)' new_events(:)'];
[~, I] = sort([EYE.event.time]);
EYE.event = EYE.event(I);

end