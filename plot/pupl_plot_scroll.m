
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
        plotinfo.legendentries{end + 1} = 'Both';
        plotinfo.t{end + 1} = EYE.times;
        plotinfo.srate{end + 1} = EYE.srate;
    end
    plotinfo.ylim = [min(structfun(@min, EYE.pupil)) max(structfun(@max, EYE.pupil))];
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

control_panel = uipanel(h,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08]);
uicontrol(control_panel,...
    'Style', 'text',...
    'String', 'X scale:',...
    'HorizontalAlignment', 'right',...
    'Units', 'normalized',...
    'Callback', @(a, b) sub_render(h),...
    'Position', [0.01 0.01 0.23 0.98]);
uicontrol(control_panel,...
    'Style', 'edit',...
    'Tag', 'xscale',...
    'String', '10s',...
    'Units', 'normalized',...
    'Callback', @(a, b) sub_render(h),...
    'Position', [0.26 0.01 0.23 0.98]);
uicontrol(control_panel,...
    'Style', 'checkbox',...
    'Tag', 'displayevents',...
    'String', 'Display events',...
    'Value', 0,...
    'Units', 'normalized',...
    'Position', [0.51 0.01 0.48 0.98],...
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
axes(p);
set(h, 'UserData', struct(...
    'plotinfo', plotinfo,...
    'EYE', EYE,...
    'type', type));

sub_render(h);

end

function sub_render(h)

%% Render data

ud = get(h, 'UserData');

try
    % Test for typo in timestr
    parsetimestr(get(findobj(h, 'Tag', 'xscale'), 'String'), 1);
catch
    return % Typo in timestr
end
sliderval = get(findobj(h, 'Style', 'slider'), 'Value'); % Between 0 and 1;

cla; hold on
% Display data
plotinfo = ud.plotinfo;
for dataidx = 1:numel(plotinfo.data)
    ndata = numel(plotinfo.data{dataidx});
    srate = plotinfo.srate{dataidx};
    x_scale = parsetimestr(get(findobj(h, 'Tag', 'xscale'), 'String'), ud.EYE.srate);
    t_start = ud.EYE.ur.times(1) + sliderval * (ud.EYE.ur.times(end) - ud.EYE.ur.times(1) - x_scale);
    t_end = t_start + x_scale;
    win_idx = plotinfo.t{dataidx} >= t_start & plotinfo.t{dataidx} <= t_end;
    plot(plotinfo.t{dataidx}(win_idx), plotinfo.data{dataidx}(win_idx), plotinfo.colours{dataidx});
end
x_limits = [t_start t_end];
xlim(x_limits);
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
        currevents = find(event_times >= x_limits(1) & event_times <= x_limits(end));
        cont = true;
        warn_events = 50;
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
            n = 30; % Max events to draw before restarting from top of span
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