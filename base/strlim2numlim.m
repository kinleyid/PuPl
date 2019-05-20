
function currLim = strlim2numlim(currStr, data, limType)

if isstr(currStr)
    if ~isempty(strfind(currStr, '%'))
        ppn = str2double(strrep(currStr, '%', ''))/100;
        vec = sort(data);
        vec = vec(~isnan(vec));
        if strcmpi(limType, 'Lower')
            currLim = vec(max(1, round(ppn*numel(vec))));
        else
            currLim = vec(min(numel(vec), round((1 - ppn)*numel(vec))));
        end
    else
        currLim = str2num(currStr);
    end
else
    currLim = currStr;
end

if isempty(currLim)
    if strcmp(limType, 'Lower')
        currLim = -inf;
    else
        currLim = inf;
    end
end