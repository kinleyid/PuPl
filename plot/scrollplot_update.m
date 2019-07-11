function scrollplot_update(a)

axes(a);

UserData = get(a, 'UserData');

plotinfo = UserData.plotinfo;
EYE = UserData.EYE;
x = UserData.x;
srate = UserData.srate;
xtimes = (x - 1)/srate;

cla; hold on
% Display data
for dataidx = 1:numel(plotinfo.data)
    plot(xtimes, plotinfo.data{dataidx}(x), plotinfo.colours{dataidx});
end
xlim([xtimes(1) xtimes(end)]);
xlabel('Time (s)');
ylabel('Pupil size');
% Display events
if ~isempty(EYE.event)
    currevents = find(ismember([EYE.event.latency], x));
    for idx = 1:numel(currevents)
        eventIdx = currevents(idx);
        t = (EYE.event(eventIdx).latency - 1)/EYE.srate;
        plot(repmat(t, 1, 2), plotinfo.ylim, 'k');
        % Jitter Y location in case many events occur in rapid
        % succession
        n = 30;
        spn = 0.8;
        currYlims = plotinfo.ylim;
        yLoc = currYlims(1) + abs(diff(currYlims)) * (spn - mod(idx, n) * spn / n);
        try
            text(t, yLoc, num2str(EYE.event(eventIdx).type),...
                'FontSize', 8,...
                'Rotation', 10,...
                'Interpreter', 'none');
        catch
            text(t, yLoc, num2str(EYE.event(eventIdx).type),...
                'FontSize', 8,...
                'Rotation', 10);
        end
    end
end
ylim(plotinfo.ylim);

legend(plotinfo.legendentries{:});

set(a, 'UserData', UserData);

end