
function gazescatter(a, EYE)

axes(a)
s = scatter(...
        EYE.gaze.x,...
        EYE.gaze.y,...
        5, 'k', 'filled');
try
    alpha(s, 0.1);
end
xlabel('Gaze x')
ylabel('Gaze y');

end