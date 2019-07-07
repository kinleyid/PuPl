
function out = getfromur(EYE, type)

switch(type)
    case 'diam'
        out = struct(...
            'left', EYE.urdiam.left,...
            'right', EYE.urdiam.right);
        %{
        out = struct(...
            'left', mean([
                EYE.urDiam.left.x
                EYE.urDiam.left.y]),...
            'right', mean([
                EYE.urDiam.right.x
                EYE.urDiam.right.y]));
        %}
    case 'gaze'
        out = struct(...
            'x', mean([
                EYE.urgaze.x.left
                EYE.urgaze.y.left]),...
            'y', mean([
                EYE.urgaze.x.right
                EYE.urgaze.y.left]));
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