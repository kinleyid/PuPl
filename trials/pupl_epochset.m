
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
        q = 'Overwrite existing epoch sets?';
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
    while true
        currname = inputdlg('Name of epoch set?');
        if isempty(currname)
            return
        else
            currname = currname{:};
        end
        currmembers = pupl_event_UIget(pupl_epoch_get(EYE, [], '_ev'), sprintf('Events in set "%s"', currname));
        if isempty(currmembers)
            return
        end
        args.setdescriptions = [
            args.setdescriptions
            struct(...
                'name', currname,...
                'members', {currmembers})];
            a = questdlg('Add another epoch set?');
        switch a
            case 'Yes'
                continue
            case 'No'
                break
            otherwise
                return
        end
    end
end
%{
for i = 1:numel(args.setdescriptions)
    fprintf('Set %s contains:\n', args.setdescriptions(i).name);
    if any(cellfun(@isnumeric, args.setdescriptions(i).members))
        fprintf('\t"%s" (regexp)\n', args.setdescriptions(i).members{2});
    else
        fprintf('\t%s\n', args.setdescriptions(i).members{:});
    end
end
%}
outargs = args;

end

function EYE = sub_epochset(EYE, varargin)

args = parseargs(varargin{:});

overwrite = args.overwrite;
setdescriptions = args.setdescriptions;

if overwrite
    EYE.epochset = [];
end

EYE.epochset = [EYE.epochset setdescriptions(:)'];
if args.verbose
    for setidx = 1:numel(setdescriptions)
        epochidx = find(pupl_epoch_sel(EYE, [], setdescriptions(setidx).members));
        fprintf('Set %s contains %d trials\n',...
            setdescriptions(setidx).name,...
            numel(epochidx));
    end
end

end
