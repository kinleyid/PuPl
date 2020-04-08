
function out = pupl_filt(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_filt(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'data' []
    'win' []
    'avfunc' []
    'width' []
    'cfg' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.data)
    q = 'Filter which data?';
    args.data = questdlg(q, q, 'Pupil size', 'Gaze', 'Cancel', 'Pupil size');
    switch args.data
        case 'Pupil size'
            args.data = 'pupil';
        case 'Gaze'
            args.data = 'gaze';
        otherwise
            return
    end
end

if ~strcmp(args.avfunc, 'median')
    if isempty(args.win)
        winOptions = {'Flat' 'Hann' 'Hamming' 'Gaussian'};
        sel = listdlgregexp(...
            'PromptString', 'What type of window?',...
            'ListString', winOptions,...
            'SelectionMode', 'single',...
            'regexp', false);
        if isempty(sel)
            return
        else
            args.win = lower(winOptions{sel});
        end
        if strcmp(args.win, 'gaussian')
            args.cfg.sd = inputdlg(sprintf('Half width of Gaussian window (in standard deviations)\n'));
            if isempty(args.cfg.sd)
                return
            else
                args.cfg.sd = str2double(args.cfg.sd{:});
            end
        end
    end
elseif strcmp(args.avfunc, 'median')
    args.win = 'flat';
end

if strcmpi(args.win, 'flat')
    if isempty(args.avfunc)
        filterOptions = {'Median' 'Mean'};
        q = 'Which type of moving average?';
        args.avfunc = lower(questdlg(q, q, filterOptions{:}, 'Cancel', 'Median'));
        if isempty(args.avfunc)
            return
        end
    end
else
    args.avfunc = 'mean';
end

if isempty(args.width)
    q = 'Window width?';
    args.width = inputdlg(q, q, 1, {'100ms'});
    if isempty(args.width)
        return
    else
        args.width = args.width{:};
    end
end

fprintf('Applying %s-window moving %s filter of width %s\n', args.win, args.avfunc, args.width);
outargs = args;

end

function EYE = sub_filt(EYE, varargin)

args = parseargs(varargin{:});

width = parsetimestr(args.width, EYE.srate, 'smp');

if strcmp(args.avfunc, 'median')
    if mod(width, 2) == 0
        width = width - 1;
    end
    try
        median(1, 'omitnan');
        avfunc = @(v) median(v, 'omitnan');
    catch
        avfunc = @nanmedian;
    end
end

fprintf('filter width is %d data points\n', width); 

switch lower(args.win)
    case 'flat'
        kern = ones(width, 1);
    case 'hann'
        kern = 0.5 * (1 - cos(2*pi * (0:width - 1)/(width - 1)));
    case 'hamming'
        kern = 0.54 - 0.46 * cos(2*pi * (0:width - 1)/(width - 1));
    case 'gaussian'
        sd = args.cfg.sd;
        x = linspace(-sd, sd, width);
        kern = 1 / sqrt(2*pi) * exp( -x.^2 / 2 );
end

kern = kern + 1; % If zeros in the kernel, the initial fft is weird. It will be normalized later

for stream = reshape(fieldnames(EYE.(args.data)), 1, [])
    fprintf('\t\tFiltering %s...', stream{:});
    switch args.avfunc
        case 'median'
            try
                EYE.(args.data).(stream{:}) = fastmedfilt(EYE.(args.data).(stream{:}), (width - 1) / 2, avfunc);
            catch % Memory error?
                EYE.(args.data).(stream{:}) = slowmedfilt(EYE.(args.data).(stream{:}), (width - 1) / 2, avfunc);
            end
            fprintf('\n');
        case 'mean'
            % FFT-based convolution
            printprog('setmax', 8);
            nkern = numel(kern);
            nconv = nkern + EYE.ndata - 1;
            data = EYE.(args.data).(stream{:});
            wasnan = isnan(data);
            data(wasnan) = 0;
            kernx = fft(kern(:)', nconv);
            printprog(1);
            kernx = kernx / max(kernx);
            datax = fft(data(:)', nconv);
            printprog(2);
            mult = kernx.*datax;
            printprog(3);
            data = ifft(mult);
            printprog(4);
            hw = floor(nkern/2) + 1;
            if hw > 1
                data = data(hw-1:end-hw);
            end
            % Correct for NaNs
            o = ones(size(data));
            o(wasnan) = 0;
            ox = fft(o(:)', nconv);
            printprog(5);
            mult = kernx.*ox;
            printprog(6);
            sums = ifft(mult);
            printprog(7);
            if hw > 1
                sums = sums(hw-1:end-hw);
            end
            % Renormalize
            data = data ./ sums;
            printprog(8);
            data(wasnan) = nan;
            EYE.(args.data).(stream{:}) = data;
    end
end

end

function out = fastmedfilt(x, n, avfunc)

% x:        data
% n:        half filter width
% filtfunc: filtering function (mean or median)

x_size = size(x);

x = x(:); % Original data
pd = [nan(n, 1); x; nan(n, 1)]; % Padded

av = avfunc(pd(bsxfun(@plus, (1:n*2+1)', (0:numel(x)-1))));
inx = ~isnan(x);
x(inx) = av(inx);

out = reshape(x, x_size);

end

function out = slowmedfilt(x, n, avfunc)

% x:        data
% n:        half filter width
% filtfunc: filtering function (mean or median)

x_size = size(x);

x = x(:); % Original data
pd = [nan(n, 1); x; nan(n, 1)]; % Padded
nd = numel(x); % Amount of data
n2 = n*2;
rb = [nan; pd(1:n2)]; % Window of data, a ring buffer

% replidx(i) is the index of the ring buffer to overwrite at step i
replidx = repmat((1:n2 + 1)', ceil(nd/(n2 + 1)), 1);
replidx = replidx(1:nd);

for latidx = 1:nd
    rb(replidx(latidx)) = pd(latidx + n2);
    if ~isnan(x(latidx))
        x(latidx) = avfunc(rb);
    end
end

out = reshape(x, x_size);

end
