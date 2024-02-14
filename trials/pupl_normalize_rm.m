function out = pupl_normalize_rm(EYE, varargin)
% Undo nornalization
%
% Inputs:
%   epoch: cell array (see pupl_epoch_sel)
%       selects the epochs to no longer normalize
% Example:
%   pupl_normalize_rm(eye_data,
%       'epoch', {1 '.'})
if nargin == 0
    out = @getargs;
else
    out = sub_normalize_rm(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'epoch' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.epoch)
    args.epoch = pupl_UI_epoch_select(...
        EYE,...
        'prompt', 'Which epochs should no longer be normalized?');
    if isempty(args.epoch)
        return
    end
end

fprintf('Removing normalization for the following epochs:\n');
txt = pupl_event_selprint(args.epoch);
fprintf('\t%s\n', txt{:});
outargs = args;

end

function EYE = sub_normalize_rm(EYE, varargin)

args = parseargs(varargin{:});

selected = find(pupl_epoch_sel(EYE, EYE.epoch, args.epoch));
rm_cnt = 0;
for epoch_idx = selected
    if isfield(EYE.epoch(epoch_idx), 'baseline')
        if numel(EYE.epoch(epoch_idx).baseline) > 1
            rm_cnt = rm_cnt + 1;
            EYE.epoch(epoch_idx).baseline = EYE.epoch(epoch_idx).baseline(1);
            EYE.epoch(epoch_idx).units(4:end) = [];
        end
    end
end

fprintf('Removed normalization for %d/%d selected trials\n', rm_cnt, numel(selected))

end