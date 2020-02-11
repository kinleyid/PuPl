function scrollplot_update(a)

axes(a);

ud = get(a, 'UserData');

plotinfo = ud.plotinfo;
EYE = ud.EYE;
x = ud.x;
srate = ud.srate;
xtimes = (x - 1)/srate;

cla; hold on
% Display data
for dataidx = 1:numel(plotinfo.data)
    plot(xtimes, plotinfo.data{dataidx}(x), plotinfo.colours{dataidx});
end
xlim([xtimes(1) xtimes(end)]);
xlabel('Time (s)');
switch ud.type
    case 'gaze'
        ylabel('Gaze coordinate');
        for ii = 1:numel(plotinfo.legendentries)
            currentry = plotinfo.legendentries{ii};
            for coord = {'x' 'y'}
                if strcontains(currentry, coord{:})
                    units = EYE.units.gaze.(coord{:});
                    additional = sprintf('(%s, %s)', units{2}, units{3});
                    currentry = sprintf('%s %s', currentry, additional);
                    break
                end
            end
            plotinfo.legendentries{ii} = currentry;
        end
    case 'pupil'
        ylabel(sprintf('Pupil %s (%s, %s)', EYE.units.pupil{:}));
end
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

set(a, 'UserData', ud);

end