function out = pupl_epochset(EYE, varargin)

%  Inputs
% EYE--struct array
% binDescriptions--struct array with fields:
%   name: name of bin
%   epochs: cell array of names of epochs included in bin

if nargin == 0
    out = @getargs;
else
    out = sub_epochset(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'setdescriptions' []
    'overwrite' []
    'verbose' true
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.overwrite)
    if any(arrayfun(@(x) ~isempty(x.epochset), EYE))
        q = 'Overwrite existing trial sets?';
        a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'Yes');
        switch a
            case 'Yes'
                args.overwrite = true;
            case 'No'
                args.overwrite = false;
            otherwise
                return
        end
    end
end

if isempty(args.setdescriptions)
    args.setdescriptions = UI_getsets(unique(mergefields(EYE, 'epoch', 'name')), 'trial set');
    if isempty(args.setdescriptions)
        return
    end
end

for i = 1:numel(args.setdescriptions)
    fprintf('Set %s contains:\n', args.setdescriptions(i).name);
    fprintf('\t%s\n', args.setdescriptions(i).members{:});
end

outargs = args;

end

function EYE = sub_epochset(EYE, varargin)

args = parseargs(varargin{:});

overwrite = args.overwrite;
setdescriptions = args.setdescriptions;

if overwrite
    EYE.epochset = [];
end
fprintf('\n');
for setidx = 1:numel(setdescriptions)
    epochidx = getepochidx(EYE, setdescriptions(setidx));
    rellims = {EYE.epoch(epochidx).rellims};
    if numel(unique(cellfun(@num2str, rellims, 'UniformOutput', 0))) > 1
        warning('You are combining epochs into a bin that do not all begin and end at the same time relative to their events');
        rellims = [];
    else
        rellims = EYE.epoch(1).rellims;
    end
    if args.verbose
        fprintf('\t\tSet %s contains %d trials\n',...
            setdescriptions(setidx).name,...
            numel(epochidx));
    end
    EYE.epochset = [EYE.epochset struct(...
        'name', setdescriptions(setidx).name,... Redundant with description, but good for backwards compatibility
        'rellims', rellims,...
        'description', setdescriptions(setidx))];
end

end