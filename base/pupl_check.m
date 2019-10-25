
function EYE = pupl_check(EYE)

% Ensures that the EYE struct array conforms to this code's expectations

% Fill in default values
defunitstruct = struct(...
    'gaze', struct(...
        'x', '',...
        'y', ''),...
    'diam', struct(...
        'left', '',...
        'right', ''));

defaults = {
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
    'datalabel' @(x)[]
    'ndata'     @(x)getndata(x)
    'BIDS'      @(x)struct('sub', x.name)
};

% Ensure missing data is replaced with nan

% Fill in defaults
for defidx = 1:size(defaults, 1)
    currfield = defaults{defidx, 1};
    if ~isfield(EYE, currfield)
        for dataidx = 1:numel(EYE)
            EYE(dataidx).(currfield) = feval(defaults{defidx, 2}, EYE(dataidx));
        end
    end
end

% Ensure zero diameter measurements are set to nan
for field = {'left' 'right'}
    data = EYE.urdiam.(field{:});
    data(data < eps) = nan;
    EYE.urdiam.(field{:}) = data;
end

% Set event to row vector
for dataidx = 1:numel(EYE)
    EYE(dataidx).event = EYE(dataidx).event(:)';
end

% Make sure coords are cellstrs
for dataidx = 1:numel(EYE)
    for field = reshape(fieldnames(EYE(dataidx).units), 1, [])
        EYE(dataidx).units.(field{:}) = structfun(@cellstr, EYE(dataidx).units.(field{:}), 'UniformOutput', false);
    end
end

% Ensure event labels are strings
if ~isempty([EYE.event])
    for dataidx = 1:numel(EYE)
        newEvents = cellfun(@num2str, {EYE(dataidx).event.type}, 'un', 0);
        [EYE(dataidx).event.type] = newEvents{:};
    end
end

% Sorts events by time
for dataidx = 1:numel(EYE)
    if ~isempty(EYE(dataidx).event)
        [~, I] = sort([EYE(dataidx).event.latency]);
        EYE(dataidx).event = EYE(dataidx).event(I);
    end
end

% Adds "beginning of recording" and "end of recording" as events if they
% don't exist
for dataidx = 1:numel(EYE)
    if ~strcmp(EYE(dataidx).event(1).type, 'Start of recording')
        EYE(dataidx).event = cat(2,...
            struct('type', 'Start of recording',...
                'time', 0,...
                'latency', 1,...
                'rt', NaN),...
            reshape(EYE(dataidx).event, 1, []));
                
    end
    if ~strcmp(EYE(dataidx).event(end).type, 'End of recording')
        EYE(dataidx).event(end+1) = ...
            struct(...
                'type', 'End of recording',...
                'time', (EYE(dataidx).ndata - 1) / EYE(dataidx).srate,...
                'latency', EYE(dataidx).ndata,...
                'rt', NaN);
    end
end

end

function ndata = getndata(EYE)

if isfield(EYE, 'ndata')
    ndata = EYE.ndata;
else
    for field = reshape(fieldnames(EYE.urdiam), 1, [])
        if ~isempty(EYE.urdiam.(field{:}))
            ndata = numel(EYE.urdiam.(field{:}));
            return
        end
    end
end

end

function name = getname(EYE)

[~, n, x] = fileparts(EYE.src);
name = [n x];

end
