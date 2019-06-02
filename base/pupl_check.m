
function outStruct = pupl_check(outStruct)

% Ensures that the EYE struct array conforms to this code's expectations

% Fill in default values
defaults = {
    'epoch' @(x)struct([])
    'bin' @(x)struct([])
    'cond' @(x)[]
    'event' @(x)struct([])
    'history' @(x){}
    'eventlog' @(x)struct([])
    'datalabel' @(x)repmat(' ', 1, getndata(x) - 1)
    'ndata' @(x)getndata(x)
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
if isfield(outStruct, 'event')
    for dataidx = 1:numel(outStruct)
        newEvents = cellfun(@num2str, {outStruct(dataidx).event.type}, 'un', 0);
        [outStruct(dataidx).event.type] = newEvents{:};
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