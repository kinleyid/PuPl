
function out = pupl_trim_short(EYE, varargin)

if nargin == 0
    out = getargs;
else
    out = sub_trim_short(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'lenthresh' [] % Max island length
    'septhresh' [] % Min island separation from nearby data
});

end

function outargs = getargs(varargin)

args = parseargs(varargin{:});

if isempty(args.lenthresh)
    prompt = 'Trim islands of data shorter than or equal to:';
    lenthresh = inputdlg(prompt, prompt, [1 50], {'150ms'});
    if isempty(lenthresh)
        return
    end
    args.lenthresh = lenthresh{:};
end

if isempty(args.septhresh)
    prompt = sprintf('Trim islands of data shorter than or equal to %s AND at least this far from the nearest other datapoint:', args.lenthresh);
    septhresh = inputdlg(prompt, prompt, [1 50], {'50ms'});
    if isempty(septhresh)
        return
    end
    args.septhresh = septhresh{:};
end

fprintf('Trimming islands of data shorter than or equal to %s and at least %s from the nearest other datapoint\n', args.lenthresh, args.septhresh)
outargs = args;

end

function EYE = sub_trim_short(EYE, varargin)

args = parseargs(varargin{:});

lenthresh = parsetimestr(args.lenthresh, EYE.srate, 'smp');
septhresh = parsetimestr(args.septhresh, EYE.srate, 'smp');

EYE = pupl_proc(EYE, @(x) trim_islands(x, lenthresh, septhresh), 'all');

end

function x = trim_islands(x, lenthresh, septhresh)

lenviolators = identifyconsecutive(x, lenthresh, @(x) ~isnan(x));
sepviolators = identifyconsecutive(x, septhresh, @isnan, 'least');
bookends = (lenviolators & [sepviolators(2:end) false]) | ...
    (lenviolators & [false sepviolators(1:end-1)]);
trimidx = findbookended(lenviolators, bookends) | ...
    findbookended(fliplr(lenviolators), fliplr(bookends));
x(trimidx) = nan;

end

function dout = findbookended(din, indic) % Can't think of a clever vectorized way to do this

dout = false(size(din));
wasindic = false;

for ii = 1:numel(din)
    if indic(ii)
        wasindic = true;
    end
    
    if din(ii)
        if wasindic
            dout(ii) = true;
        end
    else
        wasindic = false;
    end
end

end