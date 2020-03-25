
function out = getfromur(EYE, type)

switch(type)
    case 'pupil'
        try
            out = [];
            for field = reshape(fieldnames(EYE.ur.pupil), 1, [])
                out.(field{:}) = EYE.ur.pupil.(field{:});
            end
        catch
            out = struct(...
                'left', nanmean_bc([
                    EYE.ur.pupil.left.x
                    EYE.ur.pupil.left.y], 1),...
                'right', nanmean_bc([
                    EYE.ur.pupil.right.x
                    EYE.ur.pupil.right.y], 1));
        end
    case 'gaze'
        out = struct(...
            'x', mean([
                EYE.ur.gaze.x.left
                EYE.ur.gaze.x.right]),...
            'y', mean([
                EYE.ur.gaze.y.left
                EYE.ur.gaze.y.right]));
end