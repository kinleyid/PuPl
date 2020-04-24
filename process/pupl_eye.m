
function out = pupl_eye(EYE, varargin)
% Monocularize recordings
%
% Inputs:
%   keep: string
%       which eye to keep
% Example:
%   pupl_eye(eye_data,...
%       'keep', 'left');
if nargin == 0
    out = @getargs;
else
    out = sub_eye(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'keep', []
});

end

function outargs = getargs(varargin)

outargs = [];

args = parseargs(varargin{:});

if isempty(args.keep)
    opts = {'left' 'right'};
    sel = listdlgregexp(...
        'PromptString', 'Keep data from which eye?',...
        'ListString', opts,...
        'SelectionMode', 'single',...
        'regexp', false);
    if isempty(sel)
        return
    else
        args.keep = opts{sel};
    end
end

outargs = args;

fprintf('Keeping %s eye data\n', args.keep);

end

function EYE = sub_eye(EYE, varargin)

args = parseargs(varargin{:});

rm_fields = fieldnames(EYE.ur.pupil);
rm_fields = rm_fields(~strcmp(rm_fields, args.keep));

for field = rm_fields(:)'
    if isfield(EYE.ur.pupil, field{:})
        EYE.ur.pupil = rmfield(EYE.ur.pupil, field{:});
    end
    if isfield(EYE.pupil, field{:})
        EYE.pupil = rmfield(EYE.pupil, field{:});
    end
end

end
