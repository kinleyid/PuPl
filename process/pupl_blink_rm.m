
function out = pupl_blink_rm(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_blink_rm(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'trim' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.trim)
    prompt = 'Trim how much data immediately before and after blinks?';
    args.trim = inputdlg(prompt, prompt, 1, {'100ms'}); 
    if isempty(args.trim)
        return
    else
        args.trim = args.trim{:};
    end
end

outargs = args;
fprintf('Trimming %s immediately before and after blinks\n', args.trim);

end

function EYE = sub_blink_rm(EYE, varargin)

args = parseargs(varargin{:});

trimlen = parsetimestr(args.trim, EYE.srate) * EYE.srate;
isblink = EYE.datalabel == 'b';

blinkStarts = find(diff(isblink) == 1);
blinkEnds = find(diff(isblink) == -1);
if ~isempty(blinkStarts)
    if blinkStarts(1) > blinkEnds(1) % Recording starts with a blink
        blinkStarts = [1 blinkStarts];
    end
    if blinkStarts(end) > blinkEnds(end) % Recording ends with a blink
        blinkEnds = [blinkEnds EYE.ndata];
    end

    fprintf('\t\t%f%% of data are blink samples\n', 100 * nnz(EYE.datalabel == 'b') / EYE.ndata)
    nblinks = numel(blinkStarts);
    for blinkidx = 1:nblinks
        EYE = pupl_proc(EYE, @(x) rmblinks(x, [blinkStarts(blinkidx) blinkEnds(blinkidx)], trimlen));
    end
    fprintf('\t\t%f%% of data are blink-adjacent\n', 2 * 100 * nblinks * trimlen / EYE.ndata)
end

end

function x = rmblinks(x, blink, trimlen)

x(max(1, blink(1)-trimlen):min(blink(2)+trimlen, numel(x))) = NaN;

end