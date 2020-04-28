
function out = pupl_epochset(EYE, varargin)
% Define epoch sets
%
% Inputs:
%   setdescriptions: struct array
%       fields "name" and "members", where "members" selects the epochs
%       that are members of that set (see pupl_epoch_sel)
%   overwrite: boolean
%       specifies whether to overwrite pre-existing epoch sets
% Example:
%   pupl_epochset(eye_data,...
%       'setdescriptions', struct(...
%           'name', {'easy' 'medium' 'Hard'},...
%           'members', {{1 'Scene1'} {1 'Scene2'} {1 'Scene3'}}),...
%       'overwrite', true);
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
        currmembers = pupl_epoch_selUI(EYE, sprintf('Epochs in set "%s"', currname));
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
        epoch_selector = [];
        epoch_selector.filt = setdescriptions(setidx).members;
        epochs = pupl_epoch_get(EYE, epoch_selector);
        fprintf('Set %s contains %d epochs\n',...
            setdescriptions(setidx).name,...
            numel(epochs));
    end
end

end
