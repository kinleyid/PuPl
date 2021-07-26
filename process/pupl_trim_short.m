
function out = pupl_trim_short(EYE, varargin)
% Trim isolated data
%
% Citation:
% Kret, M. E., & Sjak-Shie, E. E. (2019). Preprocessing pupil size data:
% Guidelines and code. Behavior research methods, 51(3), 1336-1342.
%
% Inputs:
%   lengthresh: string
%       max. island length
%   septhresh: string
%       min. island separation from nearby data
% Example
%   pupl_trim_short(eye_data,...
%       'lenthresh', '10ms',...
%       'septhresh', '1s')
if nargin == 0
    out = @getargs;
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

function outargs = getargs(EYE, varargin)

outargs = [];

args = parseargs(varargin{:});

if isempty(args.lenthresh)
    prompt = 'Trim islands of data shorter than or equal to:';
    lenthresh = inputdlg(prompt, prompt, [1 50], {'50ms'});
    if isempty(lenthresh)
        return
    end
    args.lenthresh = lenthresh{:};
end

if isempty(args.septhresh)
    prompt = sprintf('Trim islands of data shorter than or equal to %s AND at least this far from the nearest other datapoint:', args.lenthresh);
    septhresh = inputdlg(prompt, prompt, [1 50], {'40ms'});
    if isempty(septhresh)
        return
    end
    args.septhresh = septhresh{:};
end

fprintf('Invalid islands of data are shorter than or equal to %s and at least %s from the nearest other datapoint\n', args.lenthresh, args.septhresh)
outargs = args;

end

function EYE = sub_trim_short(EYE, varargin)

args = parseargs(varargin{:});

lenthresh = parsetimestr(args.lenthresh, EYE.srate, 'smp');
septhresh = parsetimestr(args.septhresh, EYE.srate, 'smp');

if isgraphics(gcbf)
    fprintf('\n')
end

for field = reshape(fieldnames(EYE.pupil), 1, [])
    data = EYE.pupil.(field{:});
    lenviolators = identifyconsecutive(data, lenthresh, @(x) ~isnan(x));
    sepviolators = identifyconsecutive(data, septhresh, @isnan, 'least');
    bookends = (lenviolators & [sepviolators(2:end) false]) | ...
        (lenviolators & [false sepviolators(1:end-1)]);
    badidx = findbookended(lenviolators, bookends) | ...
        findbookended(fliplr(lenviolators), fliplr(bookends));
    badidx = badidx & ~isnan(badidx);
    data(badidx) = nan;
    EYE.pupil.(field{:}) = data;
    fprintf('\t\t%s:\t%f%% previously extant data removed\n', field{:}, 100*nnz(badidx)/numel(badidx));
end

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