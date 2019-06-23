
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

fields = {'sub' 'ses' 'task' 'acq'};

% How many zeros in front of subject numbers?
nz = max(length(num2str(numel(EYE))), 2);
idfmt = sprintf('%s0%dd', '%', nz);

defaults = [];
currdefaults = {'01' 'Insert task name here' '01'}';
prevID = 1;
defidx = 0;
info = struct([]);
flag = true;
for dataidx = 1:numel(EYE)
    currinput = inputdlg([
        sprintf('%s\n\n%s:', EYE(dataidx).name, fields{1})
        fields(2:end)'
    ], 'Add BIDS info', 1, [
        sprintf(idfmt, prevID)
        currdefaults
    ]);
    if isempty(currinput)
        info = [];
        return
    end
    currID = currinput{1};
    if str2double(currID) == prevID
        defidx = defidx + 1;
        if defidx == size(defaults, 2) + 1
            if flag % Currently growing defaults
                defaults = [defaults currinput(2:end)];
            else
                defidx = 1;
                prevID = prevID + 1;
            end
        end
    else
        flag = false;
        defidx = 2;
        if defidx == size(defaults, 2) + 1
            defidx = 1;
        end
        prevID = str2double(currID);
    end
    currdefaults = defaults(:, defidx);
    currinfo = struct([]);
    for fieldidx = 1:numel(fields)
        if ~isempty(currinput{fieldidx})
            currinfo(1).(fields{fieldidx}) = currinput{fieldidx};
        end
    end
    info = [info currinfo];
end

end
