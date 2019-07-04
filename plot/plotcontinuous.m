
function plotcontinuous(EYE, varargin)

p = inputParser;
addParameter(p, 'type', []);
parse(p, varargin{:});

if isempty(p.Results.type)
    q = 'Plot which type of data?';
    a = questdlg(q, q, 'Dilation', 'Gaze', 'Cancel', 'Dilation');
    switch a
        case 'Dilation'
            type = 'dilation';
        case 'Gaze'
            type = 'gaze';
        otherwise
            return
    end
else
    type = p.Results.type;
end

plotinfo = [];
if strcmpi(type, 'dilation')
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

% Plots continuous data, scrollable

if numel(unique([EYE.srate])) > 1
    uiwait(msgbox('Inconsistent sample rates'))
    return
else
    srate = EYE(1).srate;
end
nSeconds = 5;
x = 1:(nSeconds*srate);

f = figure('Name', 'Use arrow and page/h j k l keys to scroll',...
    'NumberTitle', 'off',...
    'Toolbar', 'none',...
    'MenuBar', 'none',...
    'KeyPressFcn', @moveData,...
    'UserData', struct(...
        'plotinfo', plotinfo,...
        'EYE', EYE,...
        'x', x,...
        'srate', srate,...
        'axes', []));

initialplot(f)

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
UserData = get(h, 'UserData');
UserData.x = UserData.x + change*UserData.srate;
if any(UserData.x < 1)
    UserData.x = UserData.x - min(UserData.x) + 1;
end
set(h, 'UserData', UserData);

initialplot(h);

end

function initialplot(f)

figure(f);

UserData = get(f, 'UserData');
plotinfo = UserData.plotinfo;
EYE = UserData.EYE;
x = UserData.x;
srate = UserData.srate;
xtimes = (x - 1)/srate;

for plotIdx = 1:numel(plotinfo)
    cla(subplot(numel(plotinfo), 1, plotIdx)); hold on
    % Display data
    for dataIdx = 1:numel(plotinfo(plotIdx).data)
        currData = plotinfo(plotIdx).data{dataIdx};
        currData = currData(x);
        plot(xtimes, currData, plotinfo(plotIdx).colours{dataIdx});
    end
    xlim([xtimes(1) xtimes(end)]);
    if plotIdx ~= numel(plotinfo)
        xticks([]); % XTicks only on the bottom plot
    else
        xlabel('Time (s)');
    end
    % Display events
    if ~isempty(EYE(plotIdx).event)
        for eventIdx = find(ismember([EYE(plotIdx).event.latency], x))
            t = (EYE(plotIdx).event(eventIdx).latency - 1)/EYE(plotIdx).srate;
            plot(repmat(t, 1, 2), plotinfo(plotIdx).ylim, 'k');
            text(t, mean(plotinfo(plotIdx).ylim), num2str(EYE(plotIdx).event(eventIdx).type),...
                'FontSize', 8,...
                'Rotation', 20);
        end
    end
    ylim(plotinfo(plotIdx).ylim);
    text(-0.05, 0.5, EYE(plotIdx).name,...
        'Interpreter', 'none',...
        'FontSize', 8,...
        'HorizontalAlignment', 'right',...
        'Rotation', 45,...
        'Units', 'normalized');
end

end