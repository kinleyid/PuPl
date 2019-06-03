% Salvucci, D. D., & Goldberg, J. H. (2000, November). Identifying
% fixations and saccades in eye-tracking protocols. In Proceedings of the
% 2000 symposium on Eye tracking research & applications (pp. 71-78). ACM.

function EYE = dispersionsaccadeID(EYE, varargin)

p = inputParser;
addParameter(p, 'minFixationMs', []);
addParameter(p, 'dispersionThreshold', []);
parse(p, varargin{:});
callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

if isempty(p.Results.minFixationMs)
    minFixationMs = inputdlg('Minimum length of fixation (ms)', '', 1, {'100'});
    if isempty(minFixationMs)
        return
    else
        minFixationMs = str2double(minFixationMs{:});
    end
else
    minFixationMs = p.Results.minFixationMs;
end
callstr = sprintf('%s''minFixationMs'', %s, ', callstr, all2str(minFixationMs));

if isempty(p.Results.dispersionThreshold)
    dispersionThreshold = inputdlg('Dispersion threshold', '', 1, {'30'});
    if isempty(dispersionThreshold)
        return
    else
        dispersionThreshold = str2double(dispersionThreshold);
    end
else
    dispersionThreshold = p.Results.dispersionThreshold;
end
callstr = sprintf('%s''dispersionThreshold'', %s)', callstr, all2str(minFixationMs));

fprintf('Identifying saccades using a dispersion algorithm...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s... ', EYE(dataidx).name);
    s = 1; % window start
    w = round(minFixationMs / 1000 * EYE.srate) - 1; % window size
    e = s + w;
    while true
        if e > EYE(dataidx).ndata
            EYE(dataidx).datalabel(s:e - 2) = 'f';
            break
        else
            currDispersion =...
                max(EYE(dataidx).gaze.x(s:e)) - min(EYE(dataidx).gaze.x(s:e)) +...
                max(EYE(dataidx).gaze.y(s:e)) - max(EYE(dataidx).gaze.y(s:e));
            if currDispersion < dispersionThreshold
                e = e + 1; % expand window
            else
                EYE(dataidx).datalabel(s:e - 2) = 'f'; % Label previous window as fixation
                EYE(dataidx).datalabel(e - 1) = 's'; % Label new point as saccade
                s = e;
                e = s + w;
            end
        end
    end
    fprintf('%f%% points marked as saccades\n', 100 * sum(EYE(dataidx).datalabel == 's') / numel(EYE(dataidx).datalabel));
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
end
fprintf('Done\n');

end