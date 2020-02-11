
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
        winOptions = {'Flat' 'Hann' 'Hamming'};
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

fprintf('Applying %s filter of %s on either side\n', args.avfunc, args.width);
outargs = args;

end

function EYE = sub_filt(EYE, varargin)

args = parseargs(varargin{:});

width = round(parsetimestr(args.width, EYE.srate) * EYE.srate);
if mod(width, 2) == 0
    width = width - 1;
end
fprintf('filter width is %d data points\n', width); 

switch lower(args.avfunc)
    case 'median'
        try
            median(1, 'omitnan');
            avfunc = @(v) median(v, 'omitnan');
        catch
            avfunc = @nanmedian;
        end
    case 'mean'
        try
            median(1, 'omitnan');
            avfunc = @(v) mean(v, 'omitnan');
        catch
            avfunc = @nanmean;
        end
end

switch lower(args.win)
    case 'flat'
        win = ones(width, 1);
    case 'hann'
        win = 0.5 * (1 - cos(2*pi * (0:width - 1)/(width - 1)));
    case 'hamming'
        win = 0.54 - 0.46 * cos(2*pi * (0:width - 1)/(width - 1));
end

usefast = true;

for stream = reshape(fieldnames(EYE.(args.data)), 1, [])
    fprintf('\t\tFiltering %s...', stream{:});
    
    if strcmpi(args.win, 'flat')
        try
            EYE.(args.data).(stream{:}) = fastmvavfilt(EYE.(args.data).(stream{:}), (width - 1) / 2, avfunc);
        catch % Memory error?
            EYE.(args.data).(stream{:}) = mvavfilt(EYE.(args.data).(stream{:}), (width - 1) / 2, avfunc);
        end
    else
        try
            EYE.(args.data).(stream{:}) = fastwinmvavfilt(EYE.(args.data).(stream{:}), (width - 1) / 2, win);
        catch % Memory error?
            EYE.(args.data).(stream{:}) = winmvavfilt(EYE.(args.data).(stream{:}), (width - 1) / 2, win);
        end
    end
    fprintf('\n');
end

end

function out = mvavfilt(x, n, avfunc)

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

function out = fastmvavfilt(x, n, avfunc)

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

function out = winmvavfilt(x, n, win)

% x:        data
% n:        half filter width
% win:      window

x_size = size(x);

x = x(:); % Original data
xz = x;
xz(isnan(x)) = 0; % Original data, but with zeros instead of NaNs
win = win(:)'; % Window
pd = [nan(n, 1); xz; nan(n, 1)]; % Padded
nd = numel(x); % Amount of data
n2 = n*2;
rb = [nan; pd(1:n2)]; % Window of data, a ring buffer

% replidx(i) is the index of the ring buffer to overwrite at step i
replidx = repmat((1:n2 + 1)', ceil(nd/(n2 + 1)), 1);
replidx = replidx(1:nd);

% widx(:, i) is the mapping from the window shape to the ring buffer
% i.e. windowed = rb .* ws(widx(:, i)) at step i
widx = arrayfun(@(x) circshift((1:n2 + 1), x), 1:nd, 'UniformOutput', false);
widx = reshape([widx{:}], n2 + 1, nd);

for latidx = 1:nd
    rb(replidx(latidx)) = pd(latidx + n2);
    if ~isnan(x(latidx))
        cw = win(widx(:, latidx));
        x(latidx) = cw * rb / sum(cw(rb ~= 0));
    end
end

out = reshape(x, x_size);

end

function out = fastwinmvavfilt(x, n, win)

% x:        data
% n:        half filter width
% win:      window

x_size = size(x);

x = x(:); % Original data
pd = [nan(n, 1); x; nan(n, 1)]; % Padded

av = bsxfun(@times, win(:), pd(bsxfun(@plus, (1:n*2+1)', (0:numel(x)-1))));
inx = ~isnan(x);
av = av(:, inx);
p_idx = mat2cell(~isnan(av), size(av, 1), ones(1, size(av, 2)));
av = nansum_bc(av ./ cellfun(@(idx) sum(win(idx)), p_idx));
x(inx) = av;

out = reshape(x, x_size);

end