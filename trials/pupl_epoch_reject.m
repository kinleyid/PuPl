
function out = pupl_epoch_reject(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_epoch_reject(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
    'method' []
    'cfg' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.method)
    method_options = {
        'Proportion missing data' 'ppnmissing'
        'Extreme pupil size' 'extremepupil'
        'Blink proximity' 'blink'
        'Reaction time' 'rt'
        'Event attributes' 'event'
        'Saccades' 'sacc'
    };
    sel = listdlgregexp(...
        'PromptString', 'Reject trials on what basis?',...
        'ListString', method_options(:, 1),...
        'SelectionMode', 'single',...
        'regexp', false);
    if isempty(sel)
        return
    end
    args.method = method_options{sel, 2};
end

if isempty(args.cfg)
    switch args.method
        case 'ppnmissing'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) nnz(isnan(x))/numel(x), pupl_epoch_getdata(e)), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'lims', [0 1],...
                'threshname', 'Proportion of data missing');
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
        case 'extremepupil'
            units = sprintf('%s (%s, %s)', EYE(1).units.epoch{:});
            if numel(EYE) > 1
                tmp = [EYE.units];
                if ~isequal(tmp.epoch)
                    units = 'size';
                end
            end
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) max(abs(x)), pupl_epoch_getdata(e)), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', sprintf('Max abs. pupil %s in epoch', units));
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
        case 'blink'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) nnz(diff(x == 'b') == 1), pupl_epoch_getdata(e, [], 'datalabel')), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', sprintf('Number of blinks'));
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
        case 'rt'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) mergefields(e, 'epoch', 'event', 'rt'), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', 'Reaction time');
            if isempty(thresh)
                return
            end
            args.cfg.thresh = thresh;
        case 'event'
            args.cfg.sel = pupl_event_UIget(pupl_epoch_get(EYE, [], '_ev'), 'Reject epochs associated with which events?');
            if isempty(args.cfg.sel)
                return
            end
        case 'sacc'
            thresh = UI_cdfgetrej(...
                arrayfun(@(e) cellfun(@(x) nnz(diff(x(1:end-1) == 's') == 1), pupl_epoch_getdata(e, [], 'interstices')), EYE, 'UniformOutput', false),...
                'names', {EYE.name},...
                'dataname', 'epochs',...
                'threshname', sprintf('Number of saccades'));
            if isempty(thresh)
                return
            else
                args.cfg.thresh = thresh;
            end
    end
end

outargs = args;

end

function EYE = sub_epoch_reject(EYE, varargin)

args = parseargs(varargin{:});

switch args.method
    case 'ppnmissing'
        data = cellfun(@(x) nnz(isnan(x))/numel(x), pupl_epoch_getdata(EYE));
        rejidx = data > parsedatastr(args.cfg.thresh, data);
    case 'extremepupil'
        data = cellfun(@(x) max(abs(x)), pupl_epoch_getdata(EYE));
        rejidx = data > parsedatastr(args.cfg.thresh, data);
    case 'blink'
        data = cellfun(@(x) nnz(diff(x == 'b') == 1), pupl_epoch_getdata(EYE, [], 'datalabel'));
        rejidx = data > parsedatastr(args.cfg.thresh, data);
    case 'rt'
        data = mergefields(EYE, 'epoch', 'event', 'rt');
        rejidx = data > parsedatastr(args.cfg.thresh, data);
    case 'event'
        rejidx = pupl_event_sel(pupl_epoch_get(EYE, [], '_ev'), args.cfg.sel);
    case 'sacc'
        rejidx = cellfun(@(x) any(x(1:end-1) == 's'), pupl_epoch_getdata(EYE, [], 'interstices'));
    case 'undo'
        rejidx = false(1, numel(EYE.epoch));
        [EYE.epoch.reject] = deal(false);
end

[EYE.epoch(rejidx).reject] = deal(true);

fprintf('%d new epochs rejected, %d epochs rejected in total\n', nnz(rejidx), nnz([EYE.epoch.reject]));

end