
function computereactiontimes(EYE, varargin)

p = inputParser;
addParameter(p, 'onsets', []);
addParameter(p, 'responses', []);
parse(p, varargin{:})

if isempty(p.Results.onsets)
    [~, onsets] = listdlgregexp(...
        'PromptString', 'Which events mark the onset of a trial?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')));
    if isempty(onsets)
        return
    end
else
    onsets = p.Results.onsets;
end
if isempty(p.Results.responses)
    [~, responses] = listdlgregexp(...
        'PromptString', 'Which events mark a response?',...
        'ListString', unique(mergefields(EYE, 'event', 'type')));
    if isempty(responses)
        return
    end
else
    responses = p.Results.responses;
end

callstr = getcallstr(p);

fprintf('Computing reaction times...\n');
for dataidx = 1:numel(EYE)
    % fprintf('\t%s...', EYE(dataidx).name);
    nResps = 0;
    curronsets = find(ismember({EYE(dataidx).event.type}, onsets));
    currresponses = find(ismember({EYE(dataidx).event.type}, responses));
    responsetimes = [EYE(dataidx).event(currresponses).time];
    for onsetidx = 1:numel(curronsets)
        responseidx = responsetimes >= EYE(dataidx).event(curronsets(onsetidx)).time;
        if onsetidx < numel(curronsets)
            responseidx = responseidx & ...
                responsetimes < EYE(dataidx).event(curronsets(onsetidx + 1)).time;
        end
        responseidx = find(responseidx, 1);
        if isempty(responseidx)
            rt = nan;
        else
            rt = EYE(dataidx).event(currresponses(responseidx)).time - ...
                EYE(dataidx).event(curronsets(onsetidx)).time;
            nResps = nResps + 1;
        end
        EYE(dataidx).event(curronsets(onsetidx)).rt = rt;
    end
    fprintf('%d/%d events have responses\n', nResps, numel(curronsets));
    EYE(dataidx).history{end+1} = callstr;
end
fprintf('Done\n');

end