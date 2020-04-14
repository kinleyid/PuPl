
function pupl_plot_scroll(h, EYE, varargin)

%% Get data

p = inputParser;
addParameter(p, 'type', []);
parse(p, varargin{:});

set(ancestor(h, 'figure'), 'Name', EYE.name);

if isempty(p.Results.type)
    q = 'Plot which type of data?';
    h = questdlg(q, q, 'Pupil size', 'Gaze', 'Cancel', 'Dilation');
    switch h
        case 'Pupil size'
            type = 'pupil';
        case 'Gaze'
            type = 'gaze';
        otherwise
            return
    end
else
    type = p.Results.type;
end

plotinfo = struct(...
    'data', [],...
    'legendentries', [],...
    'colours', [],...
    't', [],...
    'srate', []);
colours = {'b' 'r'};
n = 1;
if strcmpi(type, 'pupil')
    for side = {'left' 'right'}
        if isfield(EYE.pupil, side{:})
            plotinfo.data = [
                plotinfo.data
                {
                    getfield(getfromur(EYE, 'pupil'), side{:})
                    EYE.pupil.(side{:})
                }
            ];
            plotinfo.legendentries = [
                plotinfo.legendentries
                {
                    ['Unprocessed ' side{:}]
                    [upper(side{:}(1)) side{:}(2:end)]
                }
            ];
            plotinfo.colours = [
                plotinfo.colours
                {
                    sprintf('%s:', colours{n})
                    colours{n}
                }
            ];
            n = n + 1;
            plotinfo.t = [
                plotinfo.t
                {
                    EYE.ur.times
                    EYE.times
                }
            ];
            plotinfo.srate = [
                plotinfo.srate
                {
                    EYE.ur.srate
                    EYE.srate
                }
            ];
        end
    end
    if n == 3 % Both fields present
        plotinfo.data{end + 1} = mergelr(EYE);
        plotinfo.colours{end + 1} = 'k';
        plotinfo.legendentries{end + 1} = 'Binocular average';
        plotinfo.t{end + 1} = EYE.times;
        plotinfo.srate{end + 1} = EYE.srate;
    end
    plotinfo.ylim = [min(structfun(@min, EYE.pupil)) max(structfun(@max, EYE.pupil))];
    % Get datalabel
    if any(EYE.datalabel == 'b')
        s = find([false diff(EYE.datalabel == 'b') == 1]);
        e = find([diff(EYE.datalabel == 'b') == -1 false]);
        t = EYE.times(:);
        
        t = [t(s) t(s) t(s) t(s) t(e) t(e) t(e) t(e)];
        t = t';
        t = t(:)';
        y = plotinfo.ylim;
        d = [[nan y(:)' nan]; [nan y(:)' nan]];
        d = d';
        d = d(:);
        d = repmat(d, numel(s), 1);
        plotinfo.data{end + 1} = d(:)';
        plotinfo.colours{end + 1} = 'g';
        plotinfo.legendentries{end + 1} = 'Blink';
        plotinfo.t{end + 1} = t;
        plotinfo.data{end} = [plotinfo.data{end} nan(1, EYE.ndata)];
        plotinfo.t{end} = [plotinfo.t{end} EYE.times(:)'];
        plotinfo.srate{end + 1} = EYE.srate;
    end
elseif strcmpi(type, 'gaze')
    plotinfo.data = {
        getfield(getfromur(EYE, 'gaze'), 'x')
        getfield(getfromur(EYE, 'gaze'), 'y')
        EYE.gaze.x
        EYE.gaze.y};
    plotinfo.colours = {
        'b:'
        'r:'
        'b'
        'r'};
    plotinfo.legendentries = {
        'Unprocessed x'
        'Unprocessed y'
        'x'
        'y'};
    plotinfo.t = {
        EYE.ur.times
        EYE.ur.times
        EYE.times
        EYE.times};
    plotinfo.srate = {
        EYE.ur.srate
        EYE.ur.srate
        EYE.srate
        EYE.srate};
    plotinfo.ylim = [min(structfun(@min, EYE.gaze)) max(structfun(@max, EYE.gaze))];
elseif strcmpi(type, 'id')
    dl = double(EYE.datalabel);
    plotinfo.data = {dl};
    plotinfo.colours = {'r'};
    plotinfo.legendentries = {'Data label'};
    plotinfo.ylim = [min(dl) max(dl)];
end

%% Prepare plot

c1 = uipanel(h,...
    'Units', 'normalized',...
    'Title', 'Start',...
    'Position', [0.01 0.01 0.23 0.08]);
uicontrol(c1,...
    'Style', 'edit',...
    'Tag', 't_start',...
    'String', sprintf('%ss', num2str(EYE.ur.times(1))),...
    'Units', 'normalized',...
    'Callback', @(a, b) sub_render(h),...
    'Position', [0.01 0.01 0.98 0.98]);
c2 = uipanel(h,...
    'Units', 'normalized',...
    'Title', 'Scale',...
    'Position', [0.26 0.01 0.23 0.08]);
uicontrol(c2,...
    'Style', 'edit',...
    'Tag', 't_scale',...
    'String', '10s',...
    'Units', 'normalized',...
    'Callback', @(a, b) sub_render(h),...
    'Position', [0.01 0.01 0.98 0.98]);
uicontrol(h,...
    'Style', 'checkbox',...
    'Tag', 'displayevents',...
    'String', 'Display events',...
    'Value', 0,...
    'Units', 'normalized',...
    'Position', [0.51 0.01 0.23 0.08],...
    'Callback', @(a, b) sub_render(h));
uicontrol('Parent', h,...
    'Style', 'slider',...
    'SliderStep', [0.002 0.02],...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.08],...
    'Callback', @(a, b) sub_render(h));
p = uipanel(h,...
    'Units', 'normalized',...
    'Position', [0.01 0.21 0.98 0.78]);
axes('Parent', p);
set(h, 'UserData', struct(...
    'plotinfo', plotinfo,...
    'EYE', EYE,...
    'type', type,...
    'scale', struct(...
        't_start', get(findobj(h, 'Tag', 't_start'), 'String'),...
        't_scale', get(findobj(h, 'Tag', 't_scale'), 'String'),...
        'slider', 0)));

sub_render(h);

end

function sub_render(h)

%% Render data

ud = get(h, 'UserData');

% See if any scale changes have happened since last time
t_start_edit = findobj(h, 'Tag', 't_start');
new_t_start = get(t_start_edit, 'String');

t_scale_edit = findobj(h, 'Tag', 't_scale');
new_t_scale = get(t_scale_edit, 'String');

slider = findobj(h, 'Style', 'slider');
new_sliderval = get(slider, 'Value');

% Time edges of recording
t_min = ud.EYE.times(1);
t_max = ud.EYE.times(end);

if new_sliderval ~= ud.scale.slider % Check first for slider changes, since it can change quickest
    t_scale = parsetimestr(ud.scale.t_scale, ud.EYE.srate);
    t_start = t_min + new_sliderval * (t_max - t_scale - t_min);
    % Reset text box
    set(t_start_edit, 'String', sprintf('%ss', num2str(t_start)));
elseif ~strcmp(new_t_start, ud.scale.t_start)
    t_start = parsetimestr(new_t_start, ud.EYE.srate);
    t_scale = parsetimestr(ud.scale.t_scale, ud.EYE.srate);
    % Adjust if out of bounds
    if t_start + t_scale > t_max
        t_start = t_max - t_scale;
    elseif t_start < t_min
        t_start = t_min;
    end
    set(t_start_edit, 'String', sprintf('%ss', num2str(t_start)));
    % Adjust slider value
    set(slider, 'Value', (t_start - t_min) / (t_max - t_scale - t_min));
elseif ~strcmp(new_t_scale, ud.scale.t_scale)
    t_start = parsetimestr(ud.scale.t_start, ud.EYE.srate);
    t_scale = parsetimestr(new_t_scale, ud.EYE.srate);
    % Adjust if out of bounds
    if t_start + t_scale > t_max
        t_scale = t_max - t_start;
    end
    set(t_scale_edit, 'String', sprintf('%ss', num2str(t_scale)));
    % Slider value is set in part by t scale, so adjust:
    set(slider, 'Value', (t_start - t_min) / (t_max - t_scale - t_min));
else
    t_start = parsetimestr(ud.scale.t_start, ud.EYE.srate);
    t_scale = parsetimestr(ud.scale.t_scale, ud.EYE.srate);
end

ud.scale.t_start = get(t_start_edit, 'String');
ud.scale.t_scale = get(t_scale_edit, 'String');
ud.scale.slider = get(slider, 'Value');
set(h, 'UserData', ud);

cla; hold on
% Display data
plotinfo = ud.plotinfo;
for dataidx = 1:numel(plotinfo.data)
    t_win = [t_start t_start + t_scale];
    win_idx = plotinfo.t{dataidx} >= t_win(1) & plotinfo.t{dataidx} <= t_win(2);
    plot(plotinfo.t{dataidx}(win_idx), plotinfo.data{dataidx}(win_idx), plotinfo.colours{dataidx});
end
xlim(t_win);
xlabel('Time (s)');
switch ud.type
    case 'gaze'
        ylabel('Gaze coordinate');
        for ii = 1:numel(plotinfo.legendentries)
            currentry = plotinfo.legendentries{ii};
            for coord = {'x' 'y'}
                if strcontains(currentry, coord{:})
                    units = ud.EYE.units.gaze.(coord{:});
                    additional = sprintf('(%s, %s)', units{2}, units{3});
                    currentry = sprintf('%s %s', currentry, additional);
                    break
                end
            end
            plotinfo.legendentries{ii} = currentry;
        end
    case 'pupil'
        ylabel(sprintf('Pupil %s (%s, %s)', ud.EYE.units.pupil{:}));
end
if get(findobj(h, 'Tag', 'displayevents'), 'Value')
    % Display events
    if ~isempty(ud.EYE.event)
        event_times = [ud.EYE.event.time];
        currevents = find(event_times >= t_win(1) & event_times <= t_win(2));
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
                t = ud.EYE.event(eventIdx).time;
                plot(repmat(t, 1, 2), plotinfo.ylim, 'k');
                currYlims = plotinfo.ylim;
                yLoc = double(currYlims(1) + abs(diff(currYlims)) * (spn - mod(currevents(idx), n) * spn / n));
                txt = ud.EYE.event(eventIdx).name;
                try
                    text(t, yLoc, txt,...
                        'FontSize', 8,...
                        'Rotation', 10,...
                        'Interpreter', 'none');
                catch
                    text(t, yLoc, ud.EYE.event(eventIdx).name,...
                        'FontSize', 8,...
                        'Rotation', 10);
                end
            end
        end
    end
end
ylim(plotinfo.ylim);

legend(plotinfo.legendentries{:});



end