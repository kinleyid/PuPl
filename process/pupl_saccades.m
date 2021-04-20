function out = pupl_saccades(EYE, varargin)
% Identify saccades/fixations

% Salvucci, D. D., & Goldberg, J. H. (2000, November). Identifying
% fixations and saccades in eye-tracking protocols. In Proceedings of the
% 2000 symposium on Eye tracking research & applications (pp. 71-78). ACM.

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
    'overwrite' []
});

end

function outargs = getargs(EYE, varargin)

outargs = [];

args = parseargs(varargin{:});

if isempty(args.overwrite)
    if any([EYE.interstices] ~= ' ')
        a = questdlg('Overwrite previous interstitial labels?');
        switch a
            case 'Yes'
                args.overwrite = true;
            case 'No'
                args.overwrite = false;
            otherwise
                return
        end
    end
end

if isempty(args.method)
    q = 'Which method?';
    args.method = lower(questdlg(q, q, 'Velocity', 'Dispersion', 'Cancel', 'Velocity'));
    if isempty(args.method) || strcmp(args.method, 'cancel')
        return
    end
end

if isempty(args.cfg)
    switch args.method
        case 'velocity'
            data = arrayfun(@velocity, EYE, 'UniformOutput', false);
            args.cfg.thresh = UI_cdfgetrej([data{:}],...
                'threshname', 'Gaze velocity',...
                'outcomename', 'marked as saccades');
            if isempty(args.cfg.thresh)
                return
            end
            fprintf('Identifying saccades using I-VT algorithm with a velocity threshold of %s\n', args.cfg.thresh);
        case 'dispersion'
            args.cfg.minfix = inputdlg('Minimum fixation length', '', 1, {'100ms'});
            if isempty(args.cfg.minfix)
                return
            else
                args.cfg.minfix = args.cfg.minfix{:};
            end

            args.cfg.thresh = inputdlg('Dispersion threshold', '', 1, {'30'});
            if isempty(args.cfg.thresh)
                return
            else
                args.cfg.thresh = str2double(args.cfg.thresh{:});
            end
            fprintf('Identifying saccades using I-DT algorithm with a dispersion threshold of %f and a minimum fixation length of %s\n', args.cfg.thresh, args.cfg.minfix);
    end
end

outargs = args;

end

function EYE = sub_saccades(EYE, varargin)

args = parseargs(varargin{:});

new_datalabel = repmat(' ', size(EYE.interstices));

if args.overwrite
    EYE.interstices = new_datalabel;
end

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
        w = parsetimestr(args.cfg.minfix, EYE.srate, 'smp') - 1;
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

if args.overwrite
    EYE.interstices = new_datalabel;
else
    % If we aren't overwriting, don't overwrite old saccades
    EYE.interstices(EYE.interstices ~= 's') = new_datalabel(EYE.interstices ~= 's');
end

n_sacc = nnz(diff(EYE.interstices == 's') == 1);
nmins = EYE.ndata / EYE.srate / 60;
fprintf('%f%% of intertices marked as saccades\n', 100 * nnz(EYE.interstices == 's') / EYE.ndata);
fprintf('%d saccades in %0.2f minutes of recording (%.2f blinks/min)\n', n_sacc, nmins, n_sacc/nmins)

end

function out = velocity(EYE)

out = sqrt(diff(EYE.gaze.x).^2 + diff(EYE.gaze.y).^2);

end