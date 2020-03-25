
function EYE = pupl_check(EYE)

% Ensures that the EYE struct array conforms to this code's expectations

global pupl_globals

% Fill in default values
defunitstruct = struct(...
    'gaze', struct(...
        'x', {{'x' 'unknown units' 'unknown relative position'}},...
        'y', {{'y' 'unknown units' 'unknown relative position'}}),...
    'pupil', {{'diameter' 'unknown units' 'assumed absolute'}});

defaults = {
    'srate'     @(x)[]
    'src'       @(x)[]
    'name'      @(x)getname(x)
    'getraw'    @(x)''
    'coords'    @(x)[]
    'units'     @(x)defunitstruct
    'epoch'     @(x)struct([])
    'epochset'  @(x)struct([])
    'cond'      @(x)''
    'event'     @(x)struct([])
    'history'   @(x){}
    'eventlog'  @(x)struct([])
    'datalabel' @(x)repmat(' ', 1, getndata(x))
    'ndata'     @(x)getndata(x)
    'BIDS'      @(x)struct('sub', x.name)
};

% Fill in defaults
for defidx = 1:size(defaults, 1)
    currfield = defaults{defidx, 1};
    if ~isfield(EYE, currfield)
        for dataidx = 1:numel(EYE)
            EYE(dataidx).(currfield) = feval(defaults{defidx, 2}, EYE(dataidx));
        end
    end
end

for dataidx = 1:numel(EYE)
    % Set precision
    EYE(dataidx) = pupl_proc(EYE(dataidx), str2func(pupl_globals.precision), 'all');
    
    % Set event to row vector
    EYE(dataidx).event = EYE(dataidx).event(:)';
    
    baseeventstruct = [];
    if ~isempty(EYE(dataidx).event)
        % Convert event names to strings
        newEvents = cellfun(@num2str, {EYE(dataidx).event.name}, 'UniformOutput', false);
        [EYE(dataidx).event.name] = newEvents{:};
        % Sort events by time of occurrence
        [~, I] = sort([EYE(dataidx).event.time]);
        EYE(dataidx).event = EYE(dataidx).event(I);
        
        ids = [EYE(dataidx).event.uniqid];
        for field = reshape(fieldnames(EYE(dataidx).event(1)), 1, [])
            baseeventstruct.(field{:}) = [];
        end
    else
        ids = 0;
    end
    % Add "beginning of recording" and "end of recording" as events if they don't exist
    % Add fieldnames of other events
    startev = baseeventstruct;
    startev.name = 'Start of recording';
    startev.time = EYE(dataidx).times(1);
    startev.uniqid = max(ids) + 1;
    endev = baseeventstruct;
    endev.name = 'End of recording';
    endev.time = EYE(dataidx).times(end);
    endev.uniqid = max(ids) + 2;
    if isempty(EYE(dataidx).event)
        EYE(dataidx).event = [startev endev];
    else
        if ~strcmp(EYE(dataidx).event(1).name, 'Start of recording')
            startev = fieldconsistency(startev, EYE(dataidx).event);
            EYE(dataidx).event = cat(2, startev, reshape(EYE(dataidx).event, 1, []));
        end
        if ~strcmp(EYE(dataidx).event(end).name, 'End of recording')
            endev = fieldconsistency(endev, EYE(dataidx).event);
            EYE(dataidx).event(end+1) = endev;
        end
    end
    
    if ~isempty(EYE(dataidx).epoch)
        % Sort epochs by event time
        [~, I] = sort(pupl_epoch_get(EYE(dataidx), [], 'time'));
        EYE(dataidx).epoch = EYE(dataidx).epoch(I);
        % Keep units of epochs consistent with pupil size units
        EYE(dataidx).units.epoch(1:2) = EYE(dataidx).units.pupil(1:2);
        % The third element, the relative size, may have been set by the
        % baseline correction:
        if ~isfield(EYE(dataidx).epoch, 'baseline') || isempty(EYE(dataidx).units.epoch(3))
            EYE(dataidx).units.epoch(3) = EYE(dataidx).units.pupil(3);
        end
    end
    
    % Compute amount of data missing
    nmissing = 0;
    nstreams = 0;
    for field = reshape(fieldnames(EYE(dataidx).pupil), 1, [])
        if ~isempty(EYE(dataidx).pupil.(field{:}))
            nmissing = nmissing + nnz(isnan(EYE(dataidx).pupil.(field{:})));
            nstreams = nstreams + 1;
        end
    end
    EYE(dataidx).ppnmissing = nmissing / nstreams / EYE(dataidx).ndata;
end

end

function ndata = getndata(EYE)

if isfield(EYE, 'ndata')
    ndata = EYE.ndata;
else
    for field = reshape(fieldnames(EYE.ur.pupil), 1, [])
        if ~isempty(EYE.ur.pupil.(field{:}))
            ndata = numel(EYE.ur.pupil.(field{:}));
            return
        end
    end
end

end

function name = getname(EYE)

[~, n, x] = fileparts(EYE.src);
name = [n x];

end
