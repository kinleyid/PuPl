
function getinfo(n, fields, initialDefaults)

% How many zeros in front of subject numbers?
nz = max(numel(num2str(n), 2));
fmt = sprintf('%s0%dd', '%', nz);

defaults = [];
currdefaults = initialDefaults;
prevID = 1;
defidx = 0;
info = struct([]);
flag = true;
for dataidx = 1:n
    currinput = inputdlg([
        sprintf('%s\n\n%s:', EYE(dataidx).name, fields{1})
        fields(2:end)'
    ], 'Add BIDS info', 1, [
        sprintf(fmt, prevID)
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