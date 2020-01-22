
function out = getfromur(EYE, type)

switch(type)
    case 'diam'
        try
            out = struct(...
                'left', EYE.urdiam.left,...
                'right', EYE.urdiam.right);
        catch
            out = struct(...
                'left', mean([
                    EYE.urdiam.left.x
                    EYE.urdiam.left.y]),...
                'right', mean([
                    EYE.urdiam.right.x
                    EYE.urdiam.right.y]));
        end
    case 'gaze'
        out = struct(...
            'x', mean([
                EYE.urgaze.x.left
                EYE.urgaze.x.right]),...
            'y', mean([
                EYE.urgaze.y.left
                EYE.urgaze.y.right]));
        %{
        out = struct(...
            'x', mean([
                EYE.urGaze.x.left
                EYE.urGaze.y.left]),...
            'y', mean([
                EYE.urGaze.x.right
                EYE.urGaze.y.left]));
        %}

end