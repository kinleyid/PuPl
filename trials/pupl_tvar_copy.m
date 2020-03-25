
function out = pupl_tvar_copy(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_tvar_copy(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'onsets' []
    'offsets' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.onsets)
    args.onsets = pupl_event_UIget([EYE.event], 'Which events mark the beginning of a trial?');
    if isempty(args.onsets)
        return
    end
end

if isempty(args.offsets)
    args.offsets = pupl_event_UIget([EYE.event], 'Which events mark the end of a trial?');
    if isempty(args.offsets)
        return
    end
end

outargs = args;

end

function EYE = sub_tvar_copy(EYE, varargin)

args = parseargs(varargin{:});

onset_idxs = find(pupl_event_sel(EYE.event, args.onsets));
onset_times = [EYE.event(onset_idxs).time];
offset_idxs = find(pupl_event_sel(EYE.event, args.offsets));
offset_times = [EYE.event(offset_idxs).time];
all_rts = cell(size(onset_times));
n_rts = 0;
for trialidx = 1:numel(onset_times)
    is_resp = offset_times > onset_times(trialidx);
    if trialidx < numel(onset_times)
        is_resp = is_resp & offset_times < onset_times(trialidx + 1);
    end
    if any(is_resp)
        is_resp = find(is_resp);
        is_resp = is_resp(1);
        rt = offset_times(is_resp) - onset_times(trialidx);
        EYE.event(onset_idxs(trialidx)).rt = rt;
        EYE.event(response_idxs(is_resp)).rt = rt;
        n_rts = n_rts + 1;
        all_rts{trialidx} = rt;
    end
end

end