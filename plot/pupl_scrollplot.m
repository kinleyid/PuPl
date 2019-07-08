
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
    for dataidx = 1:numel(EYE)
        plotinfo(dataidx).data = {
            EYE(dataidx).diam.left
            EYE(dataidx).diam.right
            getfield(getfromur(EYE(dataidx), 'diam'), 'left')
            getfield(getfromur(EYE(dataidx), 'diam'), 'right')};
        plotinfo(dataidx).colours = {
            'b'
            'r'
            'b:'
            'r:'};
        plotinfo(dataidx).greyblinks = [
            true
            true
            false
            false];
        if isfield(EYE(dataidx).diam, 'both')
            plotinfo(dataidx).data{end + 1} = EYE(dataidx).diam.both;
            plotinfo(dataidx).colours{end + 1} = 'k';
            plotinfo(dataidx).greyblinks(end + 1) = true;
        end
        plotinfo(dataidx).ylim = [min(structfun(@min, EYE(dataidx).diam)) max(structfun(@max, EYE(dataidx).diam))];
    end
elseif strcmpi(type, 'gaze')
    for dataidx = 1:numel(EYE)
        plotinfo(dataidx).data = {
            EYE(dataidx).gaze.x
            EYE(dataidx).gaze.y
            getfield(getfromur(EYE(dataidx), 'gaze'), 'x')
            getfield(getfromur(EYE(dataidx), 'gaze'), 'y')};
        plotinfo(dataidx).colours = {
            'b'
            'r'
            'b:'
            'r:'};
        plotinfo(dataidx).greyblinks = [
            true
            true
            false
            false];
        plotinfo(dataidx).ylim = [min(structfun(@min, EYE(dataidx).gaze)) max(structfun(@max, EYE(dataidx).gaze))];
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