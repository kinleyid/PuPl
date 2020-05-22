
function out = pupl_evar_hg(EYE, varargin)
% Homogenize event variables within trials
%
% Inputs:
%   onsets: cell array (see pupl_events_sel)
%       selects the events signaling the onsets of trials
%   ends: cell array (see pupl_events_sel)
%       selects the events signaling the ends of trials
%   idx: boolean
%       specifies whether to add a #trial_idx event variable to keep track
%       of which epochs are part of which trials
% Example:
%   pupl_evar_hg(eye_data,...
%       'onsets', {1 'Scene'},...
%       'ends', {1 'Response'},...
%       'idx', false);
if nargin == 0
    out = @getargs;
else
    out = sub_evar_hg(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
	'onsets' []
    'ends' []
    'idx' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.onsets)
    args.onsets = pupl_event_selUI(EYE, 'Which events mark the onset of a trial?');
    if isempty(args.onsets)
        return
    end
end

if isempty(args.ends)
    args.ends = pupl_event_selUI(EYE, 'Which events mark the end of a trial? (Select none to use the event immediately preceding the next trial)');
    if isempty(args.ends)
        return
    end
end

if isempty(args.idx)
    a = questdlg('Add event variable #trial_idx (trial index) to keep track of which events are part of which trials?');
    switch a
        case 'Yes'
            args.idx = true;
        case 'No'
            args.idx = false;
        otherwise
            return
    end
end

fprintf('Homogenizing event variables within trials...\n');
fprintf('The following events mark the beginning of a trial:\n');
txt = pupl_event_selprint(args.onsets);
fprintf('\t%s\n', txt{:});
fprintf('The following events mark the end of a trial:\n');
txt = pupl_event_selprint(args.onsets);
fprintf('\t%s\n', txt{:});
if args.idx
    fprintf('Adding the event variable #trial_idx\n');
end

outargs = args;

end

function EYE = sub_evar_hg(EYE, varargin)

args = parseargs(varargin{:});

trial_onsets = find(pupl_event_sel(EYE.event, args.onsets));
if numel(args.ends) == 1 && args.ends{1} == 0
    trial_ends = [trial_onsets(2:end) - 1 numel(EYE.event)];
else
    trial_ends = find(pupl_event_sel(EYE.event, args.ends));
end

for trialidx = 1:numel(trial_onsets)
    curr_trial_idx = trial_onsets(trialidx):trial_ends(trialidx);
    evar_names = pupl_evar_getnames(EYE.event);
    for curr_evar = evar_names
        for curr_event_idx = curr_trial_idx
            var = EYE.event(curr_event_idx).(curr_evar{:});
            if ~isempty(var)
                [EYE.event(curr_trial_idx).(curr_evar{:})] = deal(var);
            end
        end
    end
    if args.idx
        [EYE.event(curr_trial_idx).trial_idx] = deal(trialidx);
    end
end

fprintf('%d event variables homogenized across %d trials\n', numel(evar_names), numel(trial_onsets));

end