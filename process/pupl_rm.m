function out = pupl_rm(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_rm(EYE, varargin{:});
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
    sel = listdlgregexp(...
        'PromptString', 'Remove recordings on what basis?',...
        'ListString', {
            'Percent missing pupil data'
            'Pupil size std. dev.'
            'Manual'
            'Percent rejected epochs'
            'Correlation between left and right pupil size'},...
        'SelectionMode', 'single');
    if isempty(sel)
        return
    else
        switch sel
            case 1
                args.method = 'missing';
            case 2
                args.method = 'std';
            case 3
                args.method = 'manual';
            case 4
                args.method = 'epochs';
        end
    end
end

if isempty(args.cfg)
    switch args.method
        case 'missing'
            missing_pcts = arrayfun(@(e) 100*(nnz(isnan(e.pupil.left)) + nnz(isnan(e.pupil.right)))/(2*e.ndata), EYE);
            args.cfg.thresh = UI_cdfgetrej(missing_pcts,...
                'dataname', 'recordings',...
                'threshname', 'Percent pupil data missing',...
                'lims', [0 100]);
            if isempty(args.cfg.thresh)
                return
            end
        case 'std'
            vars = arrayfun(@(e) (nanstd_bc(e.pupil.left) + nanstd_bc(e.pupil.right))/2, EYE);
            args.cfg.thresh = UI_cdfgetrej(vars,...
                'dataname', 'recordings',...
                'threshname', sprintf('Std. dev. of %s', lower(pupl_getunits(EYE(1), 'pupil'))));
            if isempty(args.cfg.thresh)
                return
            end
        case 'manual'
            [~, args.cfg.sel] = listdlgregexp(...
                'ListString', {EYE.name},...
                'PromptString', 'Remove which?',...
                'AllowRegexp', true);
            if isempty(args.cfg.sel)
                return
            end
        case 'epochs'
            rej_pcts = arrayfun(@(e) 100*nnz([e.epoch.reject])/numel(e.epoch), EYE);
            args.cfg.thresh = UI_cdfgetrej(rej_pcts,...
                'dataname', 'recordings',...
                'threshname', 'Percent epochs rejected',...
                'lims', [0 100]);
            if isempty(args.cfg.thresh)
                return
            end
        case 'corr'
            corrs = arrayfun(@(e) corrcoef(e.pupil.left, e.pupil.right, 'Rows', 'complete'), EYE, 'UniformOutput', false);
            corrs = cellfun(@(x) x(2, 1), corrs);
            args.cfg.thresh = UI_cdfgetrej(corrs,...
                'dataname', 'recordings',...
                'threshname', 'Correlation between left and right pupil size',...
                'func', @le,...
                'lims', [0 1]);
            if isempty(args.cfg.thresh)
                return
            end
    end
end

outargs = args;

end

function EYE = sub_rm(EYE, varargin)

args = pupl_args2struct(varargin, {
	'method' []
    'cfg' []
});

switch args.method
    case 'missing'
        data = arrayfun(@(e) 100*(nnz(isnan(e.pupil.left)) + nnz(isnan(e.pupil.right)))/(2*e.ndata), EYE);
        rmidx = data >= parsedatastr(args.cfg.thresh, data);
    case 'std'
        data = arrayfun(@(e) (nanstd_bc(e.pupil.left) + nanstd_bc(e.pupil.right))/2, EYE);
        rmidx = data >= parsedatastr(args.cfg.thresh, data);
    case 'manual'
        rmidx = regexpsel({EYE.name}, args.cfg.sel);
    case 'epochs'
        rej_pcts = arrayfun(@(e) 100*nnz([e.epoch.reject])/numel(e.epoch), EYE);
        rmidx = rej_pcts >= parsedatastr(args.cfg.thresh, rej_pcts);
    case 'corr'
        corrs = arrayfun(@(e) corrcoef(e.pupil.left, e.pupil.right, 'Rows', 'complete'), EYE, 'UniformOutput', false);
        corrs = cellfun(@(x) x(2, 1), corrs);
        rmidx = corrs <= parsedatastr(args.cfg.thresh, corrs);
end

fprintf('Removing recordings...\n')
fprintf('\t%s\n', EYE(rmidx).name);
EYE(rmidx) = [];

end