
function out = pupl_epoch_new(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_epoch(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin{:}, {
    'len' []
    'timelocking' []
    'lims' []
    'other' []
    'overwrite' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin);

if any(arrayfun(@(x) ~isempty(x.epoch), EYE)) && isempty(args.overwrite)
    q = 'Overwrite existing epochs?';
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

if isempty(args.timelocking)
    args.timelocking = pupl_event_UIget([EYE.event], 'Which are the timelocking events?');
    if isempty(args.timelocking)
        return
    end
end

if isempty(args.len)
    q = sprintf('Fixed or variable length epochs?');
    a = lower(questdlg(q, q, 'Fixed', 'Variable', 'Cancel', 'Fixed'));
    switch a
        case {'fixed' 'variable'}
            args.len = a;
        otherwise
            return
    end
end

if isempty(args.other)
    switch args.len
        case 'fixed'
            args.other = struct(...
                'when', 'after',...
                'event', args.timelocking);
        case 'variable'
            rel2 = 'Do epochs end after timelocking events or begin before timelocking events?';
            a = questdlg(rel2, rel2, 'End after', 'Begin before', 'Cancel', 'End after');
            switch a
                case 'End after'
                    args.other.when = 'after';
                    pick_next = 'ends';
                case 'Begin before'
                    args.other.when = 'before';
                    pick_next = 'beginnings';
                otherwise
                    return
            end
            args.other.event = pupl_event_UIget(...
                [EYE.event],...
                sprintf('Epoch %s are defined relative to which events?', pick_next));
            if isempty(args.other.event)
                return
            end
        otherwise
            return
    end
end

if isempty(args.lims)
    rel2 = cell(1, 2);
    rel2(1:2) = {'timelocking events'};
    if strcmp(args.len, 'variable')
        switch args.other.when
            case 'before'
                rel2{1} = 'the events that signal their beginnings';
            case 'after'
                rel2{2} = 'the events that signal their ends';
        end
    end
    args.lims = inputdlg({
        sprintf('Epochs start at this time relative to %s:', rel2{1})
        sprintf('Epochs end at this time relative to %s:', rel2{2})
    });
    if isempty(args.lims)
        return
    end
end
%{
if any(cellfun(@isnumeric, args.timelocking))
    fprintf('Epoch-defining events selected by regexp "%s"\n', args.timelocking{2});
else
    fprintf('Epoch-defining events:\n%s', sprintf('\t%s\n', args.timelocking{:}));
end
%}
% fprintf('Epochs defined from [event] + [%s] to [event] + [%s]\n', args.lims{:});

outargs = args;

end

function EYE = sub_epoch(EYE, varargin)

args = parseargs(varargin);

if args.overwrite
    [EYE.epoch] = deal([]);
end

epochs = epoch_(EYE, args.timelocking, args.lims, args.other, 'epoch');
[epochs.reject] = deal(false);
EYE.epoch = [EYE.epoch, epochs];

% Sort epochs by event time
[~, I] = sort(pupl_epoch_get(EYE, [], 'time'));
EYE.epoch = EYE.epoch(I);

% Set units for epochs
EYE.units.epoch = EYE.units.pupil;

% Set preliminary 1:1 trial set-to-trial relationship
trialnames = unique(pupl_epoch_get(EYE, [], 'name'));
epochsetdescriptions = struct(...
    'name', trialnames,...
    'members', cellfun(@(x) {x}, trialnames, 'UniformOutput', false));
EYE = pupl_epochset(EYE,...
    'setdescriptions', epochsetdescriptions,...
    'overwrite', true,...
    'verbose', false);

fprintf('%d epochs defined\n', numel(EYE.epoch));

end
