
function pupl_plot_matrix(EYE, varargin)

p = inputParser;
addParameter(p, 'dataidx', []);
addParameter(p, 'set', []);
% addParameter(p, 'byRT', []);
addParameter(p, 'include', []);
parse(p, varargin{:});

if isempty(p.Results.dataidx)
    dataidx = listdlgregexp('PromptString', 'Plot from which dataset?',...
        'ListString', {EYE.name});
    if isempty(dataidx)
        return
    end
else
    dataidx = p.Results.dataidx;
end

if isempty(p.Results.set)
    setOpts = unique(mergefields(EYE, 'epochset', 'name'));
    sel = listdlgregexp('PromptString', 'Plot from which trial set?',...
        'ListString', setOpts,...
        'SelectionMode', 'single',...
        'regexp', false);
    if isempty(sel)
        return
    end
    set = setOpts{sel};
else
    set = p.Results.set;
end

if isempty(p.Results.include)
    q = 'Plot which trials?';
    a = questdlg(q, q, 'Unrejected', 'All', 'Rejected', 'Unrejected');
    if isempty(a)
        return
    end
    include = lower(a);
else
    include = p.Results.include;
end

[data, isrej, lims] = pupl_epoch_getdata(EYE(dataidx), set);
data = cell2mat(data);

switch include
    case 'all'
        isrej = false(size(isrej));
    case 'rejected'
        isrej = ~isrej;
end
data = data(~isrej, :);

if numel(EYE) > 1
    if isequal(EYE.srate)
        srate = EYE.srate;
    else
        srate = [];
    end
else
    srate = EYE.srate;
end

if numel(lims) > 1
    if isequal(lims{:})
        lims = lims{1};
    else
        lims = [];
    end
else
    lims = lims{1};
end

nt = size(data, 2); % Number of time points
if isempty(srate)
    warning('Inconsistent sample rates');
    t = 1:nt;
else
    if isempty(lims)
        warning('Inconsistent epoch limits');
        t = (0:nt-1) / srate;
    else
        tl = parsetimestr(lims, srate);
        t = linspace(tl(1), tl(2), nt);
    end
end

figure;
ii = image(t, 1:size(data, 1), data,'CDataMapping','scaled');
try
    set(ii, 'AlphaData', ~isnan(data));
catch
    '';
end
ylabel('Trial')
xlabel('Time (s)')
cb = colorbar;
epochs = pupl_epoch_get(EYE(dataidx), set);
ylabel(cb, pupl_epoch_units(epochs));
title([EYE(dataidx).name ' ' set], 'Interpreter', 'none');

if isgraphics(gcbf)
    fprintf('Equivalent command:\n\n%s\n\n', getcallstr(p, false));
end

end