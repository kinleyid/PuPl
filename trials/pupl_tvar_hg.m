
function out = pupl_tvar_hg(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_getrt(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
	'onsets' []
    'ends' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.onsets)
    args.onsets = pupl_event_UIget([EYE.event], 'Which events mark the onset of a trial?');
    if isempty(args.onsets)
        return
    end
end

if isempty(args.ends)
    args.ends = pupl_event_UIget([EYE.event], 'Which events mark the end of a trial? (Select none to use the event immediately preceding the next trial)');
    if isempty(args.ends)
        return
    end
end

outargs = args;

end

function EYE = sub_getrt(EYE, varargin)

args = parseargs(varargin{:});

trial_onsets = find(pupl_event_sel(EYE.event, args.onsets));
if numel(args.ends) == 1 && args.ends{1} == 0
    trial_ends = [trial_onsets(2:end) - 1 numel(EYE.event)];
else
    trial_ends = find(pupl_event_sel(EYE.event, args.ends));
end

for trialidx = 1:numel(trial_onsets)
    curr_trial_idx = trial_onsets(trialidx):trial_ends(trialidx);
    fields = fieldnames(EYE.event);
    non_defaults = fields(~ismember(fields, {'name' 'time' 'uniqid'}));
    for curr_tvar = non_defaults(:)'
        for curr_event_idx = curr_trial_idx
            var = EYE.event(curr_event_idx).(curr_tvar{:});
            if ~isempty(var)
                [EYE.event(curr_trial_idx).(curr_tvar{:})] = deal(var);
            end
        end
    end
end

fprintf('%d trial variables homogenized across %d trials\n', numel(non_defaults), numel(trial_onsets));

end