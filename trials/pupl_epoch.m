
function out = pupl_epoch(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_epoch(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin{:}, {
    'timelocking' []
    'lims' []
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
    args.timelocking = pupl_event_UIget([EYE.event], 'Epoch relative to which events?');
    if isempty(args.timelocking)
        return
    end
end

if isempty(args.lims)
    args.lims = (inputdlg(...
        {sprintf('Epochs start at this time relative to events:')
        'Epochs end at this time relative to events:'}));
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
fprintf('Epochs defined from [event] + [%s] to [event] + [%s]\n', args.lims{:});

outargs = args;

end

function EYE = sub_epoch(EYE, varargin)

args = parseargs(varargin);

if args.overwrite
    [EYE.epoch] = deal([]);
end

currlims = EYE.srate * parsetimestr(args.lims, EYE.srate);
found = find(pupl_event_sel(EYE.event, args.timelocking));
for eventidx = found
    currEpoch = struct(...
        'reject', false,...
        'lims', {args.lims},...
        'event', EYE.event(eventidx).uniqid);
    abslims = pupl_event_getlat(EYE, eventidx) + currlims;
    badlimidx = 0;
    if abslims(1) < 1
        badlimidx = 1;
    elseif abslims(2) > EYE.ndata
        badlimidx = 2;
    end
    if badlimidx
        error('Event "%s" occurs at %f seconds into the recording "%s". %s from this event reaches outside the bounds of that recording (0 seconds to %f seconds).',...
            EYE.event(eventidx).name,...
            EYE.event(eventidx).time - EYE.times(1),...
            EYE.name,...
            args.lims{badlimidx},...
            EYE.times(end) - EYE.times(1))
    else
        EYE.epoch = [EYE.epoch, currEpoch];
    end
end

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

fprintf('%d trials extracted\n', numel(EYE.epoch));

end
