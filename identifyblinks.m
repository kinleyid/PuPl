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

missingPpn = missingPct/100;

fprintf('Identifying blinks...\n');
for dataIdx = 1:numel(EYE)
    fprintf('%s...', EYE(dataIdx).name);
    
    isBlink = false(size(EYE(dataIdx).urData.left));
    
    paddingLen = round(paddingTime/1000*EYE(dataIdx).srate);
    urWindow = 0:round(windowTime/1000*EYE(dataIdx).srate);
    currWindow = urWindow;
    for step = 1:(numel(EYE(dataIdx).urData.left)-numel(currWindow) + 1)
        currWindow = urWindow + step;
        if (nnz(isnan(EYE(dataIdx).urData.left(currWindow)))...
                +nnz(isnan(EYE(dataIdx).urData.right(currWindow))))...
                /(2*numel(currWindow)) >= missingPpn
            pad1 = max(1, currWindow(1)-paddingLen);
            pad2 = min(numel(EYE(dataIdx).urData.left), currWindow(end)+paddingLen);
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

end