
function out = pupl_alignbysync(EYE, varargin)
% Align eye data and event logs by sync triggers
%
% Inputs
%   eyesync: cell array
%       selects sync events in eye data (see pupl_event_sel)
%   elogsync: cell array
%       selects sync events in event log (see pupl_event_sel)
%   attach: cell array
%       selects events in event log to write to eye data (see
%       pupl_event_sel)
%   overwrite: boolean
%       overwrite event data from eye tracker?
% Example:
%   pupl_alignbysync(eye_data,...
%       'eyesync', {1 'Oemtilde'},...
%       'elogsync', {1 'sync'},...
%       'attach', {'AnswerCorrect: 1Response: 1State point' 'AnswerCorrect: 1Response: 2State point' 'AnswerCorrect: 2Response: 1State point' 'AnswerCorrect: 2Response: 2State point' 'AnswerResponse: 1State point' 'AnswerResponse: 2State point' 'Show FixState start' 'Show ResultScreenState start' 'Show SelectionState start'},...
%       'overwrite', true);
if nargin == 0
    out = @getargs;
else
    out = sub_alignbysync(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'eyesync' []
    'elogsync' []
    'attach' []
    'overwrite' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.eyesync)
    args.eyesync = pupl_event_selUI(EYE, 'Which events in the eye data are sync markers?');
    if isempty(args.eyesync)
        return
    end
end

if isempty(args.elogsync)
    [~, args.elogsync] = listdlgregexp(...
        'PromptString', 'Which events in the event logs are sync markers?',...
        'ListString', unique(mergefields(EYE, 'eventlog', 'event', 'name')),...
        'AllowRegexp', true);
    if isempty(args.elogsync)
        return
    end
end

if isempty(args.attach)
    [~, args.attach] = listdlgregexp(...
        'PromptString', 'Which events from the event log should be attached to the eye data?',...
        'ListString', unique(mergefields(EYE, 'eventlog', 'event', 'name')),...
        'AllowRegexp', true);
    if isempty(args.attach)
        return
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

function EYE = sub_alignbysync(EYE, varargin)

args = parseargs(varargin{:});

eye_sync = pupl_event_sel(EYE.event, args.eyesync);
elog_sync = pupl_event_sel(EYE.eventlog.event, args.elogsync);

eye_synctimes = [EYE.event(eye_sync).time];
elog_synctimes = [EYE.eventlog.event(elog_sync).time];

[offset_params, err] = findoffset(eye_synctimes, elog_synctimes);

if isempty(offset_params)
    error('Could not align sync markers');
else
    fprintf('Sync markers aligned with MSE %f s^2\n', err);
    fprintf('Offset: %f s\n', offset_params(2));
    fprintf('Drift parameter: %f s\n', offset_params(1));
end

attach_idx = pupl_event_sel(EYE.eventlog.event, args.attach);
elog_events = EYE.eventlog.event(attach_idx);
elog_events = fieldconsistency(elog_events, EYE.event);
elog_times = [elog_events.time];
new_times = num2cell(elog_times * offset_params(1) + offset_params(2));
[elog_events.time] = new_times{:};

if args.overwrite
    EYE.event = [];
    max_uniqid = 0;
else
    max_uniqid = max([EYE.event.uniqid]);
end

curr_events = EYE.event;

% Add new uniqids
new_ids = 1:numel(elog_events);
new_ids = num2cell(new_ids + max_uniqid);
[elog_events.uniqid] = new_ids{:};
% Append
[curr_events, elog_events] = fieldconsistency(curr_events, elog_events);
EYE.event = [curr_events(:)' elog_events(:)'];
% Sort by time
[~, I] = sort([EYE.event.time]);
EYE.event = EYE.event(I);

end
