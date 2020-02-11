% Salvucci, D. D., & Goldberg, J. H. (2000, November). Identifying
% fixations and saccades in eye-tracking protocols. In Proceedings of the
% 2000 symposium on Eye tracking research & applications (pp. 71-78). ACM.

function out = pupl_saccades(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    out = sub_saccades(EYE, varargin{:});
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
    q = 'Which method?';
    args.method = lower(questdlg(q, q, 'Velocity', 'Dispersion', 'Cancel', 'Velocity'));
    if isempty(args.method)
        return
    end
end

if isempty(args.cfg)
    switch args.method
        case 'velocity'
            data = arrayfun(@velocity, EYE, 'UniformOutput', false);
            args.cfg.thresh = UI_cdfgetrej([data{:}],...
                'outcomename', 'marked as saccades');
            if isempty(args.cfg.thresh)
                return
            end
        case 'dispersion'
            if isempty(args.cfg.minfixms)
                args.cfg.minfixms = inputdlg('Minimum fixation length (ms)', '', 1, {'100'});
                if isempty(args.cfg.minfixms)
                    return
                else
                    args.cfg.minfixms = str2double(args.cfg.minfixms{:});
                end
            end

            if isempty(args.thresh)
                args.cfg.thresh = inputdlg('Dispersion threshold', '', 1, {'30'});
                if isempty(args.cfg.thresh)
                    return
                else
                    args.cfg.thresh = str2double(args.cfg.thresh{:});
                end
            end
    end
end

outargs = args;

end

function EYE = sub_saccades(EYE, varargin)

args = parseargs(varargin{:});

new_datalabel = rep(' ', size(EYE.datalabel));

switch args.method
    case 'velocity'
        vel = velocity(EYE);
        thresh = parsedatastr(args.cfg.thresh, vel);
        issacc = vel >= thresh;
        new_datalabel(issacc) = 's';
        new_datalabel(~issacc) = 'f';
    case 'dispersion'
        thresh = str2double(num2str(args.cfg.thresh));
        s = 1; % window start
        w = round(args.cfg.minfixms / 1000 * EYE.srate) - 1; % window size
        e = s + w; % window end
        x = EYE.gaze.x;
        y = EYE.gaze.y;
        fprintf('%6.2f%%', 0)
        while true
            if e > EYE.ndata
                new_datalabel(s:e - 2) = 'f';
                fprintf('\b\b\b\b\b\b\b');
                break
            else
                fprintf('\b\b\b\b\b\b\b%6.2f%%', 100 * e / EYE.ndata);
                currdispersion = max(x(s:e)) - min(x(s:e)) + max(y(s:e)) - max(y(s:e));
                if currdispersion < thresh
                    e = e + 1; % expand window
                else
                    new_datalabel(s:e - 2) = 'f'; % Label previous window as fixation
                    new_datalabel(e - 1) = 's'; % Label new point as saccade
                    s = e;
                    e = s + w;
                end
            end
        end
end

% Only overwrite datalabels that aren't marked as, e.g., blinks
replace_idx = EYE.datalabel == ' ';
EYE.datalabel(replace_idx) = new_datalabel(replace_idx);

fprintf('%f%% of points marked as saccades\n', 100 * nnz(EYE.datalabel == 's') / EYE.ndata);

end

function out = velocity(EYE)

out = sqrt(diff(EYE.gaze.x).^2 + diff(EYE.gaze.y).^2);

end