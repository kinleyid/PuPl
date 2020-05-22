
function out = pupl_evar_del(EYE, varargin)
% Delete event variables
%
% Inputs:
%   which: cell array of strings
%       specifies the names of event variabes to be removed
% Example:
%   pupl_evar_del(eye_data,...
%       'which', {'FA' 'n_hits' 'max_hits' 'HR' 'trial_idx'});
if nargin == 0
    out = @getargs;
else
    out = sub_evar_del(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin{:}, {
    'which' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin);

if isempty(args.which)
    all_events = [EYE.event];
    evar_opts = pupl_evar_getnames(all_events);
    sel = listdlgregexp(...
        'PromptString', 'Delete which event variables?',...
        'ListString', strcat('#', evar_opts),...
        'regexp', false);
    if isempty(sel)
        return
    else
        args.which = evar_opts(sel);
    end
end

outargs = args;

fprintf('Deleting the following event variables:\n');
fprintf('\t#%s\n', args.which{:});

end

function EYE = sub_evar_del(EYE, varargin)

args = parseargs(varargin);

EYE.event = rmfield(EYE.event, args.which);

end