
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
    EYE(dataidx).history{end + 1} = callstr;
end
fprintf('Done\n');

end

function info = UI_getBIDSinfo(EYE)

fields = {'sub' 'ses' 'task' 'acq'};

% How many zeros in front of subject numbers?
nz = max(length(num2str(numel(EYE))), 2);
idfmt = sprintf('%s0%dd', '%', nz);

defaults = {'01' 'Task name here' '01'}';
currID = 1;
defidx = 0;
info = struct([]);
flag = true;
for dataidx = 1:numel(EYE)
    currinput = inputdlg([
        sprintf('%s\n\n%s:', EYE(dataidx).name, fields{1})
        fields(2:end)'
    ], 'Add BIDS info', 1, [
        sprintf(idfmt, currID)
        defaults
    ]);
    if isempty(currinput)
        info = [];
        return
    end
    currID = str2double(currinput{1}) + 1;
    defaults = currinput(2:end);
    currinfo = struct([]);
    for fieldidx = 1:numel(fields)
        if ~isempty(currinput{fieldidx})
            currinfo(1).(fields{fieldidx}) = currinput{fieldidx};
        end
    end
    info = [info currinfo];
end

end
