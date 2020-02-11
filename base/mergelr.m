
function b = mergelr(s)

b = mean([
    s.pupil.left(:)'
    s.pupil.right(:)'
]);

end