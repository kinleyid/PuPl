
function pupl_plot_events(EYE, t_win, y_lim)
% Overlay events

if ~isempty(EYE.event)
    event_times = [EYE.event.time];
    currevents = find(event_times >= t_win(1) & event_times <= t_win(end));
    cont = true;
    warn_events = 100;
    if numel(currevents) > warn_events
        q = sprintf('Attempt to display over %d events?', warn_events);
        a = questdlg(q, q, 'Yes', 'No', 'No');
        if strcmp(a, 'Yes')
            cont = true;
        else
            cont = false;
        end
    end
    if cont
        % Jitter Y location in case many events occur in rapid
        % succession
        spn = 0.8; % Y-axis span
        n = 15; % Max events to draw before restarting from top of span
        for idx = 1:numel(currevents)
            eventIdx = currevents(idx);
            t = EYE.event(eventIdx).time;
            plot(repmat(t, 1, 2), y_lim, 'k');
            currYlims = y_lim;
            yLoc = double(currYlims(1) + abs(diff(currYlims)) * (spn - mod(currevents(idx), n) * spn / n));
            txt = EYE.event(eventIdx).name;
            try
                text(t, yLoc, txt,...
                    'FontSize', 8,...
                    'Rotation', 10,...
                    'Interpreter', 'none');
            catch
                text(t, yLoc, EYE.event(eventIdx).name,...
                    'FontSize', 8,...
                    'Rotation', 10);
            end
        end
    end
end

end