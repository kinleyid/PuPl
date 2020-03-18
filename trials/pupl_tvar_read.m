
function pupl_tvar_read(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_tvar_read(EYE, varargin{:});
end

end

function args = parseargs(varargin)

args = pupl_args2struct(varargin, {
	'sel' []
    're' []
    'var' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];
args = parseargs(varargin{:});

if isempty(args.sel)
    sel = pupl_event_sel([EYE.event]);
    if isempty(sel)
        return
    end
end

if isempty(args.re)
    q = 'Input regular expression capture';
    inputdlg(
    switch args.method
        case 'missing'
            missing_pcts = arrayfun(@(e) 100*(nnz(isnan(e.pupil.left)) + nnz(isnan(e.pupil.right)))/(2*e.ndata), EYE);
            args.cfg.thresh = UI_cdfgetrej(missing_pcts,...
                'dataname', 'recordings',...
                'threshname', 'Percent pupil data missing');
            if isempty(args.cfg.thresh)
                return
            end
        case 'var'
            vars = arrayfun(@(e) (nanvar_bc(e.pupil.left) + nanvar_bc(e.pupil.right))/2, EYE);
            args.cfg.thresh = UI_cdfgetrej(vars,...
                'dataname', 'recordings',...
                'threshname', 'Percent pupil data missing');
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
        data = 100*(nnz(isnan(EYE.pupil.left)) + nnz(isnan(EYE.pupil.right)))/(2*EYE.ndata);
    case 'var'
        data = (nanvar_bc(EYE.pupil.left) + nanvar_bc(EYE.pupil.right))/2;
end

if data > parsedatastr(args.cfg.thresh, data)
    fprintf('Marked as bad');
    EYE.rm = true;
end

fprintf('\n');

end