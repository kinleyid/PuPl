function out = pupl_normalize(EYE, varargin)
% Normalize epochs according to reference epochs
%
% Inputs:
%   epoch: cell array
%       selects epochs to normalize
%   ref: cell array
%       selects reference epochs
%   mapping: string
%       specifies reference-to-epoch mapping
%   when: string
%       specifies whether reference epochs come before or after trial
%       epochs (if one:some mapping)
%   correction: string
%       specifies the normalization function
if nargin == 0
    out = @getargs;
else
    out = sub_normalize(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'epoch' []
    'ref' []
    'mapping' []
    'when' []
    'correction' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.epoch)
    args.epoch = pupl_epoch_selUI(...
        EYE,...
        'Which epochs should be normalized?');
    if isempty(args.epoch)
        return
    end
end

if isempty(args.correction)
    correction_opts = {
        'proportion of reference epoch peak'
        'proportion of reference epoch range'
    };
    sel = listdlg(...
        'PromptString', 'Normalization type',...
        'ListString', correction_opts,...
        'regexp', false);
    if isempty(sel)
        return
    else
        args.correction = correction_opts{sel};
    end
end

if isempty(args.epoch)
    args.epoch = pupl_epoch_selUI(...
        EYE,...
        'Which are the reference epochs?');
    if isempty(args.epoch)
        return
    end
end

if isempty(args.mapping)
    mapping_opts = {
        'one:some'
        'one:all'
    };
    sel = listdlgregexp(...
        'PromptString', 'Reference-to-epoch mapping',...
        'ListString', mapping_opts,...
        'regexp', false);
    if isempty(sel)
        return
    else
        args.mapping = mapping_opts{sel};
    end
end

switch args.mapping
    case 'one:some'
        if isempty(args.when)
            q = 'Do reference epochs occur before or after epochs?';
            args.when = lower(questdlg(q, q, 'Before', 'After', 'Cancel', 'Before'));
            if isempty(args.when)
                return
            end
        end
    otherwise
        args.when = 0; % Not applicable
end

outargs = args;

end

function EYE = sub_normalize(EYE, varargin)

args = parseargs(varargin{:});

switch args.correction
    case 'proportion of reference epoch peak'
        norm_func = @(tv, bv) tv / max(bv);
    case 'proportion of reference epoch range'
        norm_func = @(tv, bv) tv / (max(bv) - min(bv));
end

% get the epochs that will be normalized
norm_epoch_idx = pupl_epoch_sel(EYE, EYE.epoch, args.epoch);
norm_epochs = EYE.epoch(norm_epoch_idx);
% get candidate reference epochs
cand_reference_idx = pupl_epoch_sel(EYE, EYE.epoch, args.ref);
cand_references = EYE.epoch(cand_reference_idx);

% compute the mapping from references to epochs
switch args.mapping
    case 'one:some'
        cand_reference_times = pupl_epoch_get(EYE, cand_references, 'time');
        epoch_times = pupl_epoch_get(EYE, norm_epochs, 'time');
        references = [];
        for epoch_idx = 1:numel(epoch_times)
            switch args.when
                case 'before'
                    % Find latest reference prior to epoch
                    reference_idx = find(cand_reference_times <= epoch_times(epoch_idx), 1, 'last');
                case 'after'
                    % Find earliest reference after epoch
                    reference_idx = find(cand_reference_times >= epoch_times(epoch_idx), 1);
            end
            if isempty(reference_idx)
                epoch_ev = pupl_epoch_get(EYE, EYE.epoch(epoch_idx), '_tl');
                error('No reference epoch occurs %s the epoch associated with event %s (%f s)',...
                    args.when,...
                    epoch_ev.name,...
                    epoch_ev.time);
            end
            references = [references cand_references(reference_idx)];
        end
    case 'one:all'
        references = repmat(cand_references(1), 1, numel(norm_epochs));
end

[references.func] = deal(norm_func);

references = num2cell(references);

for epoch_idx = 1:numel(norm_epochs)
    if isfield(norm_epochs(epoch_idx), 'baseline')
        norm_epochs.baseline(2) = references(epoch_idx);
    else
        error('Epoch has not yet been baseline corrected');
    end
end

EYE.epoch(norm_epoch_idx) = norm_epochs;

end