
function out = pupl_alignbytimestamp(EYE, varargin)
% Align eye tracker data and event logs by timestamps
%
% Inputs:
%   attach: struct
%       selects the events to add from the event log (see pupl_event_select)
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
    sel = pupl_UI_event_select(EYE,...
        'prompt', 'Which events from the event log should be attached to the eye data?',...
        'from_log', true);
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

event_idx = pupl_event_select(mergefields(EYE, 'eventlog'), args.attach);
if args.overwrite
    EYE.event = struct([]);
    max_uniqid = 0;
else
    max_uniqid = max([EYE.event.uniqid]);
end

curr_events = EYE.event;
new_events = EYE.eventlog(event_idx);

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
