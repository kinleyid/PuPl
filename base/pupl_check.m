
function outStruct = pupl_check(outStruct)

% Ensures that the EYE struct array conforms to this code's expectations

% Fill in default values
defaults = {
    'name', @(x)''
    'srate', @(x)[]
    'src', @(x)[] 
    'epoch' @(x)struct([])
    'bin' @(x)struct([])
    'cond' @(x)[]
    'event' @(x)struct([])
    'isBlink' @(x)false(1, getndata(x))
    'history' @(x){}
    'eventlog' @(x)struct([])
    'datalabel' @(x)repmat(' ', 1, getndata(x) - 1)
    'ndata' @(x)getndata(x)
    'aoi' @(x)struct([])
    'aoiset' @(x)struct([])
};
for defidx = 1:size(defaults, 1)
    currfield = defaults{defidx, 1};
    if ~isfield(outStruct, currfield)
        for dataidx = 1:numel(outStruct)
            outStruct(dataidx).(currfield) = feval(defaults{defidx, 2}, outStruct(dataidx));
        end
    end
end

% Ensure event labels are strings
if ~isempty(outStruct.event)
    for dataidx = 1:numel(outStruct)
        newEvents = cellfun(@num2str, {outStruct(dataidx).event.type}, 'un', 0);
        [outStruct(dataidx).event.type] = newEvents{:};
    end
end

% Sorts events by time
for dataidx = 1:numel(outStruct)
    [~, I] = sort([outStruct(dataidx).event.latency]);
    outStruct(dataidx).event = outStruct(dataidx).event(I);
end

% Adds "beginning of recording" and "end of recording" as events if they
% don't exist
for dataidx = 1:numel(outStruct)
    if ~strcmp(outStruct(dataidx).event(1).type, 'Start of recording')
        outStruct(dataidx).event = cat(2,...
            struct('type', 'Start of recording',...
                'time', 0,...
                'latency', 1),...
            reshape(outStruct(dataidx).event, 1, []));
                
    end
    if ~strcmp(outStruct(dataidx).event(end).type, 'End of recording')
        outStruct(dataidx).event(end+1) = ...
            struct('type', 'End of recording',...
                'time', (outStruct(dataidx).ndata - 1) / outStruct(dataidx).srate,...
                'latency', outStruct(dataidx).ndata);
    end
end

end

function ndata = getndata(EYE)

if ~isempty(EYE.diam.left)
    ndata = numel(EYE.diam.left);
elseif ~isempty(EYE.diam.right)
    ndata = numel(EYE.diam.right);
elseif ~isempty(EYE.gaze.x)
    ndata = numel(EYE.gaze.x);
elseif ~isempty(EYE.gaze.y)
    ndata = numel(EYE.gaze.y);
end

end