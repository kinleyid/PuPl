function out = pupl_baseline_rm(EYE, varargin)
% Undo baseline correction
%
% Inputs:
%   epoch: cell array (see pupl_epoch_sel)
%       selects the epochs to no longer baseline correct
% Example:
%   pupl_baseline_rm(eye_data,
%       'epoch', {1 '.'})
if nargin == 0
    out = @getargs;
else
    out = sub_baseline_rm(EYE, varargin{:});
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
    args.epoch = pupl_epoch_selUI(...
        EYE,...
        'Which epochs should no longer be baseline corrected?');
    if isempty(args.epoch)
        return
    end
end

fprintf('Removing baseline correction for the following epochs:\n');
txt = pupl_event_selprint(args.epoch);
fprintf('\t%s\n', txt{:});
outargs = args;

end

function EYE = sub_baseline_rm(EYE, varargin)

args = parseargs(varargin{:});

selected = find(pupl_epoch_sel(EYE, EYE.epoch, args.epoch));
rm_cnt = 0;
for epoch_idx = selected
    if isfield(EYE.epoch(epoch_idx), 'baseline')
        if ~isempty(EYE.epoch(epoch_idx).baseline)
            rm_cnt = rm_cnt + 1;
            EYE.epoch(epoch_idx).baseline = [];
        end
    end
end

fprintf('Removed baseline correction for %d/%d selected epochs\n', rm_cnt, numel(selected))

end