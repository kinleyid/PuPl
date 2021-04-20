
function out = pupl_blink_rm(EYE, varargin)
% Remove blink/blink-adjacent samples
%
% Inputs:
%   trim: 2-element cell array of strings
%       specifies the length of pre- and post-blink data to remove
% Example:
%   pupl_blink_rm(eye_data,...
%       'trim', {'150ms', '50ms'})
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

function outargs = getargs(varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.trim)
    prompt = {
        'Remove data beginning from this long before blinks:'
        'Remove data up until this long after blinks:'
    };
    args.trim = inputdlg(prompt, '', 1, {'50ms' '150ms'}); 
    if isempty(args.trim)
        return
    end
end

outargs = args;
fprintf('Removing from %s immediately before blinks to %s immediately after\n', args.trim{1}, args.trim{2});

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
        EYE = pupl_proc(EYE, @(x) rmblinks(x, [blinkStarts(blinkidx) blinkEnds(blinkidx)], trimlen), 'all');
    end
    fprintf('\t\t%f%% of data are blink-adjacent\n', 100 * nblinks * sum(trimlen) / EYE.ndata)
end

end

function x = rmblinks(x, blink, trimlen)

x(max(1, blink(1)-trimlen(1)):min(blink(2)+trimlen(2), numel(x))) = NaN;

end