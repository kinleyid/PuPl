
function pupilsizehist(f, l, r)

a = 0.4;
axes(f); hold on;
d = [l r];
n = 4*log2(numel(d));
x1 = min(d);
x2 = max(d);
c = [x1:(x2-x1)/(n-1):x2 x2+(x2-x1)/(n-1)];
hist(l, c);
h = findobj(gca,'Type','patch');
set(h, 'EdgeColor', 'w');
set(h, 'FaceColor', [1 0 0]);
set(findobj(gca,'Type','line'), 'Marker', 'none');
try
    alpha(h, a);
end
hist(r, c);
h = findobj(gca,'Type','patch');
h = h(1);
set(h, 'EdgeColor', 'w');
set(h, 'FaceColor', [0 0 1]);
set(findobj(gca,'Type','line'), 'Marker', 'none');
try
    alpha(h, a);
end

xlabel 'Pupil diameter'
ylabel 'Data count'

h = findobj(gca,'Type','patch');
legend(h, 'Right', 'Left');

end