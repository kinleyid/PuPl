function EYE = identifyblinks(EYE, varargin)

% Adds a logical isBlink field to EYE.
%   Inputs
% missingPct--
% windowTime--in ms
% paddingTime--in ms

p = inputParser;
addParameter(p, 'missingPct', [])
addParameter(p, 'windowTime', [])
addParameter(p, 'paddingTime', [])
parse(p, varargin{:});

if any(structfun(@isempty, p.Results))
    answer = inputdlg({'Blinks defined as at least this percent missing data:'...
        'For at least this many milliseconds:'...
        'Padded by this many milliseconds:'},...
        'Blink params',...
        [1 30],...
        {'30' '100' '50'});
    if isempty(answer)
        return
    else
        answer = cellfun(@str2double, answer, 'un', 0);
        [missingPct, windowTime, paddingTime] = answer{:};
    end
else
    missingPct = p.Results.missingPct;
    windowTime = p.Results.windowTime;
    paddingTime = p.Results.paddingTime;
end

fprintf('Identifying blink as:\n')
fprintf('%f%% missing data\n', missingPct);
fprintf('For at least %f milliseconds\n', windowTime);
fprintf('Padded by %f milliseconds\n', paddingTime);

missingPpn = missingPct/100;

for dataIdx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataIdx).name);
    
    isBlink = false(size(EYE(dataIdx).isBlink));
    
    paddingLen = round(paddingTime/1000*EYE(dataIdx).srate);
    urWindow = 0:round(windowTime/1000*EYE(dataIdx).srate);
    currWindow = urWindow;
    for step = 1:(numel(EYE(dataIdx).isBlink) - numel(currWindow) + 1)
        currWindow = urWindow + step;
        [amtMissing, total] = deal(0);
        for field1 = reshape(fieldnames(EYE(dataIdx).urDiam), 1, [])
            for field2 = reshape(fieldnames(EYE(dataIdx).urDiam.(field1{:})), 1, [])
                amtMissing = amtMissing + ...
                    nnz(isnan(EYE(dataIdx).urDiam.(field1{:}).(field2{:})(currWindow)));
                total = total + numel(currWindow);
            end
        end
        if amtMissing / total >= missingPpn
            pad1 = max(1, currWindow(1)-paddingLen);
            pad2 = min(numel(EYE(dataIdx).isBlink), currWindow(end)+paddingLen);
            isBlink(pad1:pad2) = true;
        end
    end
    nBlinks = 0; wasBlink = false;
    for i = 1:numel(isBlink)
        if isBlink(i)
            if ~wasBlink
                nBlinks = nBlinks + 1;
                wasBlink = true;
            end
        else
            if wasBlink
                wasBlink = false;
            end
        end
    end
    
    fprintf('%d blinks identified\n', nBlinks);
    
    EYE(dataIdx).isBlink = isBlink;
end

fprintf('done\n')

end