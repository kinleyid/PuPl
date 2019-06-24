
function b = mergelr(s)

b = mean([
    s.diam.left(:)'
    s.diam.right(:)'
]);

end