% Salvucci, D. D., & Goldberg, J. H. (2000, November). Identifying
% fixations and saccades in eye-tracking protocols. In Proceedings of the
% 2000 symposium on Eye tracking research & applications (pp. 71-78). ACM.

function out = pupl_saccades(EYE, varargin)

if nargin == 0
    out = @getargs;
else
    
end

end

function out = getargs(EYE, varargin)

out = [];
args = pupl_args2struct(varargin, {
    'method' []
});

if isempty(args.method)
    q = 'Which method?';
    args.method = lower(questdlg(q, q, 'Velocity', 'Dispersion', 'Velocity'));
    if isempty(args.method)
        return
    end
end

switch args.method
    case 'velocity'
        threshold = UI_getthreshold(EYE);
            if isempty(threshold)
                return
            end
        else
            threshold = p.Results.threshold;
        end
    case 'dispersion'
        minfixms = inputdlg('Minimum fixation length (ms)', '', 1, {'100'});
        if isempty(minfixms)
            return
        else
            args.minfixms = str2double(minfixms{:});
        end
        
        thresh = inputdlg('Dispersion threshold', '', 1, {'30'});
        if isempty(thresh)
            return
        else
            args.thresh = str2double(thresh);
        end
end

out = args;

end