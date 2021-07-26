
function out = pupl_event_rm(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_event_rm(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'sel' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.sel)
    args.sel = pupl_UI_select(EYE, 'prompt', 'Delete which events?');
    if isempty(args.sel)
        return
    end
end

outargs = args;

printable = pupl_event_selprint(args.sel);
fprintf('Deleting the following events:\n');
fprintf('\t%s\n', printable{:});

end

function EYE = sub_event_rm(EYE, varargin)

args = parseargs(varargin{:});

rm_idx = pupl_event_sel(EYE.event, args.sel);

EYE.event(rm_idx) = [];

fprintf('%d/%d events removed\n', nnz(rm_idx), numel(rm_idx));

end

