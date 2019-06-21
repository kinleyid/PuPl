
function EYE = trimblinkadjacent(EYE, varargin)

p = inputParser;
addParameter(p, 'blinkParams', []);
addParameter(p, 'trimLen', []);
parse(p, varargin{:});
callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

if isempty(p.Results.blinkParams)
    blinkParams= inputdlg({sprintf('Blink length\n\nMin') 'Max'}, '', 1, {'10ms' '500ms'}); 
    if isempty(blinkParams)
        return
    end
else
    blinkParams = p.Results.minBlinkLen;
end
callstr = sprintf('%s''blinkParams'', %s, ', callstr, all2str(blinkParams));

if isempty(p.Results.trimLen)
    prompt = 'Trim this long adjascent to blinks';
    trimLen = inputdlg(prompt, prompt, 1, {'50ms'}); 
    if isempty(trimLen)
        return
    end
    trimLen = trimLen{:};
else
    trimLen = p.Results.trimLen;
end
callstr = sprintf('%s''trimLen'', %s)', callstr, all2str(trimLen));

fprintf('Trimming blink-adjascent points\n');
for dataidx = 1:numel(EYE)
    fprintf('\tFinding blinks in %s...\n', EYE(dataidx).name);
    currMinBlinkLen = parsetimestr(blinkParams{1}, EYE(dataidx).srate) * EYE(dataidx).srate;
    currMaxBlinkLen = parsetimestr(blinkParams{2}, EYE(dataidx).srate) * EYE(dataidx).srate;
    isblinkmin = ...
        identifyconsecutive(EYE(dataidx).diam.left, currMinBlinkLen, @isnan, 'least') |...
        identifyconsecutive(EYE(dataidx).diam.right, currMinBlinkLen, @isnan, 'least');
    isblinkmax = ...
        identifyconsecutive(EYE(dataidx).diam.left, currMaxBlinkLen, @isnan, 'most') |...
        identifyconsecutive(EYE(dataidx).diam.right, currMaxBlinkLen, @isnan, 'most');
    isblink = isblinkmin & isblinkmax;
    fprintf('\t\t%f%% of data marked as blinks\n', 100 * sum(isblink) / EYE(dataidx).ndata);
    currTrimLen = parsetimestr(trimLen, EYE(dataidx).srate) * EYE(dataidx).srate;
    blinkStarts = find(diff(isblink) == 1);
    blinkEnds = find(diff(isblink) == -1);
    if blinkStarts(1) > blinkEnds(1) % Recording starts with a blink
        blinkStarts = [1 blinkStarts];
    end
    if blinkStarts(end) > blinkEnds(end) % REcording ends with a blink
        blinkEnds = [blinkEnds EYE(dataidx).ndata];
    end
    nblinks = numel(blinkStarts);
    nmins = EYE(dataidx).ndata / EYE(dataidx).srate / 60;
    fprintf('\t\t%d blinks in %0.2f minutes of recording (%.2f blinks/min)\n', nblinks, nmins, nblinks/nmins)
    for blinkidx = 1:nblinks
        for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
            EYE(dataidx).diam.(stream{:})(...
                max(1, blinkStarts(blinkidx)-currTrimLen):blinkStarts(blinkidx)) = NaN;
            EYE(dataidx).diam.(stream{:})(...
                blinkEnds(blinkidx):min(blinkEnds(blinkidx)+currTrimLen, EYE(dataidx).ndata)) = NaN;
        end
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
end
fprintf('Done\n');

end