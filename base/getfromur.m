
function x = getfromur(EYE, type)

switch(type)
    case 'diam'
        x = struct(...
            'left', mean([
                EYE.urDiam.left.x
                EYE.urDiam.left.y]),...
            'right', mean([
                EYE.urDiam.right.x
                EYE.urDiam.right.y]));
    case 'gaze'
        x = struct(...
            'x', mean([
                EYE.urGaze.x.left
                EYE.urGaze.y.left]),...
            'y', mean([
                EYE.urGaze.x.right
                EYE.urGaze.y.left]));

end