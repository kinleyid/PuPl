
function gazescatter(EYE)

figure; hold on;
s = scatter(...
        mergefields(EYE, 'gaze', 'x'),...
        mergefields(EYE, 'gaze', 'y'),...
        5, 'k', 'filled');
try
    alpha(s, 0.1);
end
xlabel('Gaze x')
ylabel('Gaze y');

end