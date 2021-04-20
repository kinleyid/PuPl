
function out = pupl_PFE_quart(EYE)
% Correct pupil foreshortening error by piecewise quartic detrend
%
% Citation:
% Gagl, B., Hawelka, S., & Hutzler, F. (2011). Systematic influence of gaze
% position on pupil size measurement: analysis and correction. Behavior
% research methods, 43(4), 1171-1181.
if nargin == 0
    out = [];
    fprintf('Correcting pupil foreshortening error by piecewise quartic function of gaze x position\n');
else
    out = sub_PFE_quart(EYE);
end

end

function EYE = sub_PFE_quart(EYE)

pupil_fields = reshape(fieldnames(EYE.pupil), 1, []);

for field = pupil_fields
    x = EYE.gaze.x;
    y = EYE.pupil.(field{:});
    [p1, p2, cutoff, yhat] = PFE_quart(x, y);
    fprintf('Where %s < %f, modelling %s %s as:\n',...
        lower(pupl_getunits(EYE, 'gaze', 'x')),...
        cutoff,...
        field{:},...
        lower(pupl_getunits(EYE)));
    fprintf('Y = ');
    for idx = 1:numel(p1)
        if idx > 1
            fprintf(' + ');
        end
        fprintf('[%f]', p1(idx));
        o = numel(p1) - idx;
        if o > 0
            fprintf('*x^%d', o);
        end
    end
    fprintf('\nWhere %s >= %f, modelling %s pupil %s as:\n',...
        lower(pupl_getunits(EYE, 'gaze', 'x')),...
        cutoff,...
        field{:},...
        pupl_getunits(EYE));
    fprintf('Y = ');
    for idx = 1:numel(p2)
        if idx > 1
            fprintf(' + ');
        end
        fprintf('[%f]', p2(idx));
        o = numel(p2) - idx;
        if o > 0
            fprintf('*x^%d', o);
        end
    end
    fprintf('\n');
    % Put NaNs back and correct
    Pc = EYE.pupil.(field{:});
    % Check for possible distortions in pupil size
    win_len = parsetimestr('100ms', EYE.srate, 'smp', 'abs');
    pre_range = pk2pk(Pc, win_len);
    Pc = Pc(:) - yhat(:) + nanmean_bc(Pc);
    post_range = pk2pk(Pc, win_len);
    if mean(post_range) > mean(pre_range)
        warning('PuPl:PFE:newjumps',...
            'The average moving window peak-to-peak distance has increased after PFE correction. I.e., there are larger jumps in pupil size over short windows than before. You should inspect the data to make sure PFE correction has not introduced distortions.');
    end
    EYE.pupil.(field{:}) = reshape(Pc, size(EYE.pupil.(field{:})));
end

end