function scrollplot_update(a)

axes(a);

UserData = get(a, 'UserData');

plotinfo = UserData.plotinfo;
EYE = UserData.EYE;
x = UserData.x;
srate = UserData.srate;
xtimes = (x - 1)/srate;

for plotIdx = 1:numel(plotinfo)
    cla; hold on
    % Display data
    for dataIdx = 1:numel(plotinfo(plotIdx).data)
        currData = plotinfo(plotIdx).data{dataIdx};
        currData = currData(x);
        plot(xtimes, currData, plotinfo(plotIdx).colours{dataIdx});
    end
    xlim([xtimes(1) xtimes(end)]);
    xlabel('Time (s)');
    ylabel('Pupil size');
    % Display events
    if ~isempty(EYE(plotIdx).event)
        currevents = find(ismember([EYE(plotIdx).event.latency], x));
        for idx = 1:numel(currevents)
            eventIdx = currevents(idx);
            t = (EYE(plotIdx).event(eventIdx).latency - 1)/EYE(plotIdx).srate;
            plot(repmat(t, 1, 2), plotinfo(plotIdx).ylim, 'k');
            % Jitter Y location in case many events occur in rapid
            % succession
            n = 30;
            spn = 0.8;
            currYlims = plotinfo(plotIdx).ylim;
            yLoc = currYlims(1) + abs(diff(currYlims)) * (spn - mod(idx, n) * spn / n);
            try
                text(t, yLoc, num2str(EYE(plotIdx).event(eventIdx).type),...
                    'FontSize', 8,...
                    'Rotation', 10,...
                    'Interpreter', 'none');
            catch
                text(t, yLoc, num2str(EYE(plotIdx).event(eventIdx).type),...
                    'FontSize', 8,...
                    'Rotation', 10);
            end
        end
    end
    ylim(plotinfo(plotIdx).ylim);
end

set(a, 'UserData', UserData);

end