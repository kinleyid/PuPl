
function gazescatter(a, EYE)

axes(a)
s = scatter(...
        EYE.gaze.x,...
        EYE.gaze.y,...
        5, 'k', 'filled');
try
    alpha(s, 0.1);
end
xlabel(sprintf('Gaze x (%s, %s)', EYE.units.gaze.x{2:end}))
ylabel(sprintf('Gaze y (%s, %s)', EYE.units.gaze.y{2:end}))

end