
function out = pupl_filt(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    args = pupl_args2struct(varargin, {
        'datatype', []
        'filtertype', []
        'hwidth', []
    });
    
    hwidth = round(parsetimestr(args.hwidth, EYE.srate)*EYE.srate);
    fprintf('filter width is %d data points\n', hwidth*2 + 1); 
    
    switch lower(args.filtertype)
        case 'median'
            try
                median(1, 'omitnan');
                filtfunc = @(v) median(v, 'omitnan');
            catch
                filtfunc = @nanmedian;
            end
        case 'mean'
            try
                median(1, 'omitnan');
                filtfunc = @(v) mean(v, 'omitnan');
            catch
                filtfunc = @nanmean;
            end
    end
    
    switch lower(args.datatype)
        case 'dilation'
            field = 'diam';
        case 'gaze'
            field = 'gaze';
    end
    
    for stream = reshape(fieldnames(EYE.(field)), 1, [])
        fprintf('\t\tFiltering %s...', stream{:});
        EYE.(field).(stream{:}) = mvavfilt(EYE.(field).(stream{:}), hwidth, filtfunc);
        fprintf('\n');
    end
    out = EYE;
end

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = pupl_args2struct(varargin, {
    'datatype', []
    'filtertype', []
    'hwidth', []
});

if isempty(args.datatype)
    q = 'Filter which data?';
    args.datatype = questdlg(q, q, 'Dilation', 'Gaze', 'Dilation');
    if isempty(args.datatype)
        return
    end
end

if isempty(args.filtertype)
    filterOptions = {'Median' 'Mean'};
    q = 'Which type of moving average?';
    args.filtertype = questdlg(q, q, filterOptions{:}, 'Median');
    if isempty(args.filtertype)
        return
    end
end

if isempty(args.hwidth)
    q = 'Average of what length of data on either side?';
    args.hwidth = inputdlg(q, q, 1, {'100ms'});
    if isempty(args.hwidth)
        return
    else
        args.hwidth = args.hwidth{:};
    end
end

fprintf('Applying %s filter of %s on either side\n', args.filtertype, args.hwidth);
outargs = args;

end

function out = mvavfilt(x, n, filtfunc)

xSize = size(x);

x = x(:);
p = [nan(n, 1); x; nan(n, 1)];
nd = numel(x);
n2 = n*2;
w = [nan; p(1:n2)];
replidx = repmat((1:2*n + 1)', ceil(nd/(2*n + 1)), 1);
replidx = replidx(1:nd);
for latidx = 1:nd
    w(replidx(latidx)) = p(latidx + n2);
    if ~isnan(x(latidx))
       x(latidx) = filtfunc(w);
    end
end

out = reshape(x, xSize);

end