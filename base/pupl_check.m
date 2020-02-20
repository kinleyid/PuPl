
function EYE = pupl_check(EYE)

% Ensures that the EYE struct array conforms to this code's expectations

% Fill in default values
defunitstruct = struct(...
    'gaze', struct(...
        'x', {{'x' 'unknown units' 'unknown relative position'}},...
        'y', {{'y' 'unknown units' 'unknown relative position'}}),...
    'pupil', {{'diameter' 'unknown units' 'assumed absolute'}});

defaults = {
    't1'        @(x)[]
    'srate'     @(x)[]
    'src'       @(x)[]
    'name'      @(x)getname(x)
    'getraw'    @(x)''
    'coords'    @(x)[]
    'units'     @(x)defunitstruct
    'epoch'     @(x)struct([])
    'trialset'  @(x)struct([])
    'cond'      @(x)''
    'event'     @(x)struct([])
    'history'   @(x){}
    'eventlog'  @(x)struct([])
    'datalabel' @(x)repmat(' ', 1, getndata(x))
    'ndata'     @(x)getndata(x)
    'BIDS'      @(x)struct('sub', x.name)
};

if isfield(EYE, 'diam') && ~isfield(EYE, 'pupil')
    [EYE.pupil] = EYE.diam;
end

if isfield(EYE, 'urdiam') && ~isfield(EYE, 'urpupil')
    [EYE.urpupil] = EYE.urdiam;
end

% Fill in defaults
for defidx = 1:size(defaults, 1)
    currfield = defaults{defidx, 1};
    if ~isfield(EYE, currfield)
        for dataidx = 1:numel(EYE)
            EYE(dataidx).(currfield) = feval(defaults{defidx, 2}, EYE(dataidx));
        end
    end
end

% Keep units of epochs consistent with pupil size units
for dataidx = 1:numel(EYE)
    if isfield(EYE, 'epoch')
        EYE(dataidx).units.epoch(1:2) = EYE(dataidx).units.pupil(1:2);
        % The third element, the relative size, may have been set by the
        % baseline correction:
        if ~isfield(EYE(dataidx).epoch, 'baseline') || isempty(EYE(dataidx).units.epoch(3))
            EYE(dataidx).units.epoch(3) = EYE(dataidx).units.pupil(3);
        end
    end
end

% Ensure zero diameter measurements are set to nan
for dataidx = 1:numel(EYE)
    for field = {'left' 'right'}
        data = EYE(dataidx).urpupil.(field{:});
        data(data < eps) = nan;
        EYE(dataidx).urpupil.(field{:}) = data;
    end
end

% Set event to row vector
for dataidx = 1:numel(EYE)
    EYE(dataidx).event = EYE(dataidx).event(:)';
end

% Ensure event labels are strings
if ~isempty([EYE.event])
    for dataidx = 1:numel(EYE)
        newEvents = cellfun(@num2str, {EYE(dataidx).event.type}, 'un', 0);
        [EYE(dataidx).event.type] = newEvents{:};
    end
end

% Sorts events and epochs by time of occurrence
for dataidx = 1:numel(EYE)
    if ~isempty(EYE(dataidx).event)
        [~, I] = sort([EYE(dataidx).event.latency]);
        EYE(dataidx).event = EYE(dataidx).event(I);
    end
    if ~isempty(EYE(dataidx).epoch)
        [~, I] = sort(mergefields(EYE(dataidx).epoch, 'event', 'latency'));
        EYE(dataidx).epoch = EYE(dataidx).epoch(I);
    end
end

% Adds "beginning of recording" and "end of recording" as events if they
% don't exist
for dataidx = 1:numel(EYE)
    startev = struct('type', 'Start of recording',...
        'time', 0,...
        'latency', 1,...
        'rt', NaN);
    endev = struct(...
        'type', 'End of recording',...
        'time', (EYE(dataidx).ndata - 1) / EYE(dataidx).srate,...
        'latency', EYE(dataidx).ndata,...
        'rt', NaN);
    if isempty(EYE(dataidx).event)
        EYE(dataidx).event = [startev endev];
    else
        if ~strcmp(EYE(dataidx).event(1).type, 'Start of recording')
            EYE(dataidx).event = cat(2, startev, reshape(EYE(dataidx).event, 1, []));

        end
        if ~strcmp(EYE(dataidx).event(end).type, 'End of recording')
            EYE(dataidx).event(end+1) = endev;
        end
    end
end

end

function ndata = getndata(EYE)

if isfield(EYE, 'ndata')
    ndata = EYE.ndata;
else
    for field = reshape(fieldnames(EYE.urpupil), 1, [])
        if ~isempty(EYE.urpupil.(field{:}))
            ndata = numel(EYE.urpupil.(field{:}));
            return
        end
    end
end

end

function name = getname(EYE)

[~, n, x] = fileparts(EYE.src);
name = [n x];

end
