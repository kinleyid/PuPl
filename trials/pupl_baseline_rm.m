function out = pupl_baseline_rm(EYE, varargin)

%   Inputs
% correctionType: 'subtract mean' or 'percent change'
% baselineDefs: struct with fields:
%       event: event name defining baseline
%       lims: lims around events
%       
%   Outputs
% EYE: struct array

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
        end
        EYE.epoch(epoch_idx) = rmfield(EYE.epoch(epoch_idx), 'baseline');
    end
end

fprintf('Removed baseline correction for %d/%d selected trials', rm_cnt, numel(selected))

end