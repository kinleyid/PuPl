
function pupl_scrollplot(a, EYE, varargin)

p = inputParser;
addParameter(p, 'type', []);
parse(p, varargin{:});

set(ancestor(a, 'figure'), 'KeyPressFcn', @(h, e) moveData(h, e));
set(a, 'Tag', 'scrollplotaxis');

if isempty(p.Results.type)
    q = 'Plot which type of data?';
    a = questdlg(q, q, 'Dilation', 'Gaze', 'Cancel', 'Dilation');
    switch a
        case 'Dilation'
            type = 'diam';
        case 'Gaze'
            type = 'gaze';
        otherwise
            return
    end
else
    type = p.Results.type;
end

plotinfo = [];
if strcmpi(type, 'diam')
    for dataIdx = 1:numel(EYE)
        plotinfo(dataIdx).data = {
            EYE(dataIdx).diam.left
            EYE(dataIdx).diam.right
            getfield(getfromur(EYE(dataIdx), 'diam'), 'left')
            getfield(getfromur(EYE(dataIdx), 'diam'), 'right')};
        plotinfo(dataIdx).colours = {
            'b'
            'r'
            'b:'
            'r:'};
        plotinfo(dataIdx).greyblinks = [
            true
            true
            false
            false];
        if isfield(EYE(dataIdx).diam, 'both')
            plotinfo(dataIdx).data{end + 1} = EYE(dataIdx).diam.both;
            plotinfo(dataIdx).colours{end + 1} = 'k';
            plotinfo(dataIdx).greyblinks(end + 1) = true;
        end
        plotinfo(dataIdx).ylim = [min(structfun(@min, EYE(dataIdx).diam)) max(structfun(@max, EYE(dataIdx).diam))];
    end
elseif strcmpi(type, 'gaze')
    for dataIdx = 1:numel(EYE)
        plotinfo(dataIdx).data = {
            EYE(dataIdx).gaze.x
            EYE(dataIdx).gaze.y
            getfield(getfromur(EYE(dataIdx), 'gaze'), 'x')
            getfield(getfromur(EYE(dataIdx), 'gaze'), 'y')};
        plotinfo(dataIdx).colours = {
            'b'
            'r'
            'b:'
            'r:'};
        plotinfo(dataIdx).greyblinks = [
            true
            true
            false
            false];
        plotinfo(dataIdx).ylim = [min(structfun(@min, EYE(dataIdx).gaze)) max(structfun(@max, EYE(dataIdx).gaze))];
    end
end

if numel(unique([EYE.srate])) > 1
    uiwait(msgbox('Inconsistent sample rates'))
    return
else
    srate = EYE(1).srate;
end
nSeconds = 5;
x = 1:(nSeconds*srate);

set(a, 'UserData', struct(...
    'plotinfo', plotinfo,...
    'EYE', EYE,...
    'x', x,...
    'srate', srate,...
    'axes', []));

updateplot(a);

end

function updateplot(a)

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
            n = 5;
            spn = 0.6;
            currYlims = plotinfo(plotIdx).ylim;
            yLoc = currYlims(1) + abs(diff(currYlims)) * ((spn + (1 - spn)/2) - mod(idx, n) * spn / n);
            text(t, yLoc, num2str(EYE(plotIdx).event(eventIdx).type),...
                'FontSize', 8,...
                'Rotation', 20);
        end
    end
    ylim(plotinfo(plotIdx).ylim);
end

set(a, 'UserData', UserData);

end

function moveData(h, e)

switch e.Key
    case {'h', 'pageup'}
        change = -5;
    case {'l', 'pagedown'}
        change = 5;
    case {'k', 'rightarrow', 'right'}
        change = 1;
    case {'j', 'leftarrow', 'left'}
        change = -1;
    otherwise
        return
end
a = findobj('Tag', 'scrollplotaxis');
UserData = get(a, 'UserData');
UserData.x = UserData.x + change*UserData.srate;
if any(UserData.x < 1)
    UserData.x = UserData.x - min(UserData.x) + 1;
end
set(a, 'UserData', UserData);

updateplot(a);

end