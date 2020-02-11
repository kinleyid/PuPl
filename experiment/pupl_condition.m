function out = pupl_condition(EYE, varargin)

% Organize datasets into experimental conditions
%   Inputs
% EYE--struct array

if nargin == 0
    out = @getargs;
else
    out = sub_condition(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'conditions' []
    'overwrite' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.conditions)
    args.conditions = UI_getsets({EYE.name}, 'Condition');
    if isempty(args.conditions)
        return
    end
end

if isempty(args.overwrite)
    if isnonemptyfield(EYE, 'cond')
        q = 'Overwrite existing condition assignments?';
        a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
        switch a
            case 'Yes'
                args.overwrite = true;
            case 'No'
                args.overwrite = false;
            otherwise
                return
        end
    else
        args.overwrite = false;
    end
end

outargs = args;

end

function EYE = sub_condition(EYE, varargin)

args = parseargs(varargin{:});

if args.overwrite
    [EYE.cond] = deal('');
end

for condidx = 1:numel(args.conditions)
    membersidx = ismember({EYE.name}, args.conditions(condidx).members);
    for dataidx = find(membersidx)
        EYE(dataidx).cond = [EYE(dataidx).cond {args.conditions(condidx).name}];
    end
    fprintf('Condition ''%s'' contains:\n', args.conditions(condidx).name);
    fprintf('\t%s\n', args.conditions(condidx).members{:});
end

end