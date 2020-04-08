
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
    'Title', 'X start',...
    'Position', [0.01 0.01 0.23 0.08]);
uicontrol(c1,...
    'Style', 'edit',...
    'Tag', 'xstart',...
    'Units', 'normalized',...
    'Callback', @(a, b) sub_render(h),...
    'Position', [0.01 0.01 0.98 0.98]);
c2 = uipanel(h,...
    'Units', 'normalized',...
    'Title', 'X scale',...
    'Position', [0.26 0.01 0.23 0.08]);
uicontrol(c2,...
    'Style', 'edit',...
    'Tag', 'xscale',...
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
    'cfg', struct(...
        'xstart', sprintf('%ss', num2str(EYE.ur.times(1))),...
        'xscale', '10s')));

sub_render(h);

end

function sub_render(h)

%% Render data

ud = get(h, 'UserData');

% Get x start and scale

x_scale_edit = findobj(h, 'Tag', 'xscale');
try
    str = get(x_scale_edit, 'String');
    x_scale = parsetimestr(str, ud.EYE.srate);
    ud.cfg.xscale = str;
catch
    str = ud.cfg.xscale;
    x_scale = parsetimestr(str, ud.EYE.srate);
    set(x_scale_edit, 'String', str)
end
ud.cfg.xscale = x_scale;

% If there's a change in x start, we need to figure out if it's coming from
% the slider or the edit box
t_1 = ud.EYE.ur.times(1);
t_end = ud.EYE.ur.times(end);

x_start_prior = parsetimestr(ud.cfg.xstart, ud.EYE.srate);

x_start_edit = findobj(h, 'Tag', 'xstart');
try
    x_start_fromedit = parsetimestr(get(x_start_edit, 'String'), ud.EYE.srate);
    outofbounds = false;
    if x_start_fromedit < t_1
        x_start_fromedit = t_1;
        outofbounds = true;
    elseif x_start_fromedit + x_scale > t_end
        x_start_fromedit = t_end - x_scale;
        outofbounds = true;
    end
    if outofbounds
        set(x_start_edit, 'String', sprintf('%ss', num2str(x_start_fromedit)));
    end
catch
    x_start_fromedit = x_start_prior;
    set(x_start_edit, 'String', sprintf('%ss', num2str(x_start_fromedit)));
end
slider = findobj(h, 'Style', 'slider');
sliderval = get(slider, 'Value');
x_start_fromslider = t_1 + sliderval * (t_end - t_1 - x_scale);
% Round to the nearest millisecond for comparisons
if round(1000*x_start_fromedit) ~= round(1000*x_start_prior)
    % Change has occured in edit box
    x_start = x_start_fromedit;
    % Reset slider
    new_sliderval = (x_start - t_1) / (t_end - t_1 - x_scale);
    set(slider, 'Value', new_sliderval);
elseif round(1000*x_start_fromslider) ~= round(1000*x_start_prior)
    % Change has occured in slider
    x_start = x_start_fromslider;
    set(x_start_edit, 'String', sprintf('%ss', num2str(x_start)));
else
    x_start = x_start_prior;
end
ud.cfg.xstart = x_start;

set(h, 'UserData', ud);

cla; hold on
% Display data
plotinfo = ud.plotinfo;
for dataidx = 1:numel(plotinfo.data)
    t_start = x_start;
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