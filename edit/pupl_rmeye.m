
function out = pupl_rmeye(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_rmeye(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'which', []
});

end

function outargs = getargs(varargin)

outargs = [];

args = parseargs(varargin{:});

if isempty(args.which)
    opts = {'left' 'right'};
    sel = listdlg(...
        'PromptString', 'Remove data from which eye?',...
        'ListString', opts,...
        'SelectionMode', 'single');
    if isempty(sel)
        return
    else
        args.which = opts{sel};
    end
end

outargs = args;

fprintf('Removing %s eye data\n', args.which);

end

function EYE = sub_rmeye(EYE, varargin)

args = parseargs(varargin{:});

EYE.ur.pupil = rmfield(EYE.ur.pupil, args.which);
EYE.pupil = rmfield(EYE.pupil, args.which);

end
