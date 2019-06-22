
function EYE = addBIDSinfo(EYE, varargin)

p = inputParser;
addParameter(p, 'infostruct', []);
parse(p, varargin{:});
callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

if isempty(p.Results.infostruct)
    infostruct = UI_getBIDSinfo(EYE);
    if isempty(infostruct)
        return
    end
else
    infostruct = p.Results.infostruct;
end
callstr = sprintf('%s''infostruct'', %s)', callstr, all2str(infostruct));

fprintf('Adding BIDS info...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...\n', EYE(dataidx).name);
    for field = reshape(fieldnames(infostruct(dataidx)), 1, [])
        fprintf('\t\t%s:\t%s\n', field{:}, infostruct(dataidx).(field{:}));
    end
    EYE(dataidx).BIDS = infostruct(dataidx);
end
fprintf('Done\n');

end

function info = UI_getBIDSinfo(EYE)

fields = {'sub' 'task' 'ses' 'run'};

% How many zeros in front of subject numbers?
nz = max(length(num2str(numel(EYE))), 2);
idfmt = sprintf('%s0%dd', '%', nz);

defaults = [];
currdefaults = repmat({''}, numel(fields) - 1, 1);
prevID = 0;
defidx = 1;
info = struct([]);
for dataidx = 1:numel(EYE)
    currinput = inputdlg([
        sprintf('%s\n\n%s:', EYE(dataidx).name, fields{1})
        fields(2:end)'
    ], 'Add BIDS info', 1, [
        sprintf(idfmt, dataidx)
        currdefaults
    ]);
    if isempty(currinput)
        info = [];
        return
    end
    currID = currinput{1};
    if strcmp(currID, prevID)
        defidx = defidx + 1;
        if defidx > size(defaults, 2)
            defaults = [defaults currinput(2:end)];
        end
    else
        defidx = 1;
    end
    currdefaults = defaults(:, defidx);
    prevID = currID;
    currinfo = struct([]);
    for fieldidx = 1:numel(fields)
        if ~isempty(currinput{fieldidx})
            currinfo(1).(fields{fieldidx}) = currinput{fieldidx};
        end
    end
    info = [info currinfo];
end

end
