
function out = getfromur(EYE, type)

switch(type)
    case {'diam' 'pupil'}
        try
            out = struct(...
                'left', EYE.urpupil.left,...
                'right', EYE.urpupil.right);
        catch
            out = struct(...
                'left', mean([
                    EYE.urpupil.left.x
                    EYE.urpupil.left.y]),...
                'right', mean([
                    EYE.urpupil.right.x
                    EYE.urpupil.right.y]));
        end
    case 'gaze'
        out = struct(...
            'x', mean([
                EYE.urgaze.x.left
                EYE.urgaze.x.right]),...
            'y', mean([
                EYE.urgaze.y.left
                EYE.urgaze.y.right]));
end